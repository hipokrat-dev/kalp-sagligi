import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUsername => _auth.currentUser?.displayName;
  String? get currentEmail => _auth.currentUser?.email;

  Future<void> init() async {
    // Firebase Auth handles initialization via Firebase.initializeApp()
  }

  Future<bool> tryAutoLogin() async {
    return _auth.currentUser != null;
  }

  Future<({bool success, String message})> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      final trimmedName = displayName.trim();
      if (trimmedName.length < 2) {
        return (success: false, message: 'Ad en az 2 karakter olmalı');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.updateDisplayName(trimmedName);
      await credential.user?.reload();

      // Create user profile in Firestore
      await _db.collection('users').doc(credential.user!.uid).set({
        'displayName': trimmedName,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return (success: true, message: 'Kayıt başarılı');
    } on FirebaseAuthException catch (e) {
      return (success: false, message: _translateError(e.code));
    } catch (e) {
      return (success: false, message: 'Bir hata oluştu: $e');
    }
  }

  Future<({bool success, String message})> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return (success: true, message: 'Giriş başarılı');
    } on FirebaseAuthException catch (e) {
      return (success: false, message: _translateError(e.code));
    } catch (e) {
      return (success: false, message: 'Bir hata oluştu: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<({bool success, String message})> resetPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return (success: true, message: 'Şifre sıfırlama bağlantısı e-postanıza gönderildi');
    } on FirebaseAuthException catch (e) {
      return (success: false, message: _translateError(e.code));
    } catch (e) {
      return (success: false, message: 'Bir hata oluştu: $e');
    }
  }

  Future<({bool success, String message})> changeUsername(String newName) async {
    try {
      final trimmed = newName.trim();
      if (trimmed.length < 2) {
        return (success: false, message: 'Ad en az 2 karakter olmalı');
      }

      await currentUser?.updateDisplayName(trimmed);
      await currentUser?.reload();

      // Update in Firestore
      if (currentUserId != null) {
        await _db.collection('users').doc(currentUserId).update({
          'displayName': trimmed,
        });
      }

      return (success: true, message: 'Kullanıcı adı güncellendi');
    } catch (e) {
      return (success: false, message: 'Bir hata oluştu: $e');
    }
  }

  Future<({bool success, String message})> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 6) {
        return (success: false, message: 'Yeni şifre en az 6 karakter olmalı');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: currentEmail!,
        password: currentPassword,
      );
      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);

      return (success: true, message: 'Şifre başarıyla değiştirildi');
    } on FirebaseAuthException catch (e) {
      return (success: false, message: _translateError(e.code));
    } catch (e) {
      return (success: false, message: 'Bir hata oluştu: $e');
    }
  }

  String _translateError(String code) {
    return switch (code) {
      'email-already-in-use' => 'Bu e-posta adresi zaten kayıtlı',
      'invalid-email' => 'Geçersiz e-posta adresi',
      'weak-password' => 'Şifre çok zayıf, en az 6 karakter olmalı',
      'user-not-found' => 'Bu e-posta ile kayıtlı kullanıcı bulunamadı',
      'wrong-password' => 'Şifre hatalı',
      'invalid-credential' => 'E-posta veya şifre hatalı',
      'too-many-requests' => 'Çok fazla deneme yaptınız, lütfen bekleyin',
      'user-disabled' => 'Bu hesap devre dışı bırakılmış',
      'network-request-failed' => 'İnternet bağlantısı yok',
      _ => 'Bir hata oluştu ($code)',
    };
  }
}
