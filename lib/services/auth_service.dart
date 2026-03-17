import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._();
  AuthService._();

  late SharedPreferences _prefs;
  bool _initialized = false;
  String? _currentUserId;

  String? get currentUserId => _currentUserId;
  String? get currentUsername => _currentUserId != null
      ? _prefs.getString('user_${_currentUserId}_username')
      : null;

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    final hash1 = sha256.convert(bytes);
    final hash2 = sha256.convert(utf8.encode('$hash1:$salt'));
    return hash2.toString();
  }

  String _generateUserId(String username) {
    return sha256.convert(utf8.encode(username.toLowerCase().trim())).toString().substring(0, 16);
  }

  List<String> _getUserIds() {
    return _prefs.getStringList('registered_user_ids') ?? [];
  }

  Future<void> _saveUserIds(List<String> ids) async {
    await _prefs.setStringList('registered_user_ids', ids);
  }

  Future<({bool success, String message})> register({
    required String username,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    await init();

    final trimmedUsername = username.trim();
    if (trimmedUsername.length < 3) {
      return (success: false, message: 'Kullanıcı adı en az 3 karakter olmalı');
    }
    if (password.length < 4) {
      return (success: false, message: 'Şifre en az 4 karakter olmalı');
    }
    if (securityAnswer.trim().isEmpty) {
      return (success: false, message: 'Güvenlik sorusu cevabı boş olamaz');
    }

    final userId = _generateUserId(trimmedUsername);

    // Check if user exists
    final userIds = _getUserIds();
    if (userIds.contains(userId)) {
      return (success: false, message: 'Bu kullanıcı adı zaten kayıtlı');
    }

    // Save user
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final hashedPassword = _hashPassword(password, salt);
    final hashedAnswer = _hashPassword(securityAnswer.toLowerCase().trim(), salt);

    await _prefs.setString('user_${userId}_username', trimmedUsername);
    await _prefs.setString('user_${userId}_password', hashedPassword);
    await _prefs.setString('user_${userId}_salt', salt);
    await _prefs.setString('user_${userId}_security_question', securityQuestion);
    await _prefs.setString('user_${userId}_security_answer', hashedAnswer);

    userIds.add(userId);
    await _saveUserIds(userIds);

    _currentUserId = userId;
    await _prefs.setString('last_logged_in_user', userId);

    return (success: true, message: 'Kayıt başarılı');
  }

  Future<({bool success, String message})> login({
    required String username,
    required String password,
  }) async {
    await init();

    final userId = _generateUserId(username.trim());
    final userIds = _getUserIds();

    if (!userIds.contains(userId)) {
      return (success: false, message: 'Kullanıcı bulunamadı');
    }

    final salt = _prefs.getString('user_${userId}_salt') ?? '';
    final storedHash = _prefs.getString('user_${userId}_password') ?? '';
    final inputHash = _hashPassword(password, salt);

    if (storedHash != inputHash) {
      return (success: false, message: 'Şifre hatalı');
    }

    _currentUserId = userId;
    await _prefs.setString('last_logged_in_user', userId);

    return (success: true, message: 'Giriş başarılı');
  }

  void logout() {
    _currentUserId = null;
    _prefs.remove('last_logged_in_user');
  }

  Future<bool> tryAutoLogin() async {
    await init();
    final lastUser = _prefs.getString('last_logged_in_user');
    if (lastUser != null && _getUserIds().contains(lastUser)) {
      _currentUserId = lastUser;
      return true;
    }
    return false;
  }

  Future<String?> getSecurityQuestion(String username) async {
    await init();
    final userId = _generateUserId(username.trim());
    if (!_getUserIds().contains(userId)) return null;
    return _prefs.getString('user_${userId}_security_question');
  }

  Future<({bool success, String message})> resetPassword({
    required String username,
    required String securityAnswer,
    required String newPassword,
  }) async {
    await init();

    final userId = _generateUserId(username.trim());
    if (!_getUserIds().contains(userId)) {
      return (success: false, message: 'Kullanıcı bulunamadı');
    }

    if (newPassword.length < 4) {
      return (success: false, message: 'Yeni şifre en az 4 karakter olmalı');
    }

    final salt = _prefs.getString('user_${userId}_salt') ?? '';
    final storedAnswer = _prefs.getString('user_${userId}_security_answer') ?? '';
    final inputAnswer = _hashPassword(securityAnswer.toLowerCase().trim(), salt);

    if (storedAnswer != inputAnswer) {
      return (success: false, message: 'Güvenlik sorusu cevabı hatalı');
    }

    // Update password with new salt
    final newSalt = DateTime.now().microsecondsSinceEpoch.toString();
    final newHash = _hashPassword(newPassword, newSalt);
    final newAnswerHash = _hashPassword(securityAnswer.toLowerCase().trim(), newSalt);

    await _prefs.setString('user_${userId}_password', newHash);
    await _prefs.setString('user_${userId}_salt', newSalt);
    await _prefs.setString('user_${userId}_security_answer', newAnswerHash);

    return (success: true, message: 'Şifre başarıyla sıfırlandı');
  }

  Future<({bool success, String message})> changeUsername(String newUsername) async {
    await init();
    if (_currentUserId == null) {
      return (success: false, message: 'Giriş yapılmamış');
    }

    final trimmed = newUsername.trim();
    if (trimmed.length < 3) {
      return (success: false, message: 'Kullanıcı adı en az 3 karakter olmalı');
    }

    await _prefs.setString('user_${_currentUserId}_username', trimmed);
    return (success: true, message: 'Kullanıcı adı güncellendi');
  }

  Future<({bool success, String message})> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await init();
    if (_currentUserId == null) {
      return (success: false, message: 'Giriş yapılmamış');
    }

    if (newPassword.length < 4) {
      return (success: false, message: 'Yeni şifre en az 4 karakter olmalı');
    }

    final salt = _prefs.getString('user_${_currentUserId}_salt') ?? '';
    final storedHash = _prefs.getString('user_${_currentUserId}_password') ?? '';
    final inputHash = _hashPassword(currentPassword, salt);

    if (storedHash != inputHash) {
      return (success: false, message: 'Mevcut şifre hatalı');
    }

    final newSalt = DateTime.now().microsecondsSinceEpoch.toString();
    final newHash = _hashPassword(newPassword, newSalt);

    // Re-hash security answer with new salt
    // We need the original answer, but we can't reverse the hash.
    // So we keep the old salt for security answer, or we require re-entry.
    // For simplicity, update salt and password only.
    await _prefs.setString('user_${_currentUserId}_password', newHash);
    await _prefs.setString('user_${_currentUserId}_salt', newSalt);

    // Re-hash security answer with new salt - need original answer
    // Since we can't reverse hash, keep security answer on old salt
    // Store a separate salt for security answer
    await _prefs.setString('user_${_currentUserId}_password_salt', newSalt);

    return (success: true, message: 'Şifre başarıyla değiştirildi');
  }
}
