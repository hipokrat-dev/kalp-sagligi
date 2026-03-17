import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class FriendData {
  final String uid;
  final String name;
  final String email;
  final DateTime addedAt;

  FriendData({
    required this.uid,
    required this.name,
    required this.email,
    required this.addedAt,
  });

  factory FriendData.fromMap(Map<String, dynamic> map) {
    return FriendData(
      uid: map['friendUid'] ?? '',
      name: map['friendName'] ?? '',
      email: map['friendEmail'] ?? '',
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUid;
  final String fromName;
  final String fromEmail;
  final String toUid;
  final String toEmail;
  final String status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.fromEmail,
    required this.toUid,
    required this.toEmail,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUid: data['fromUid'] ?? '',
      fromName: data['fromName'] ?? '',
      fromEmail: data['fromEmail'] ?? '',
      toUid: data['toUid'] ?? '',
      toEmail: data['toEmail'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class FriendPublicData {
  final int steps;
  final int water;
  final int riskScore;
  final String riskLevel;

  FriendPublicData({
    required this.steps,
    required this.water,
    required this.riskScore,
    required this.riskLevel,
  });
}

class FriendsService {
  static final FriendsService instance = FriendsService._();
  FriendsService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _currentUid => AuthService.instance.currentUserId;
  String? get _currentEmail => AuthService.instance.currentEmail;
  String? get _currentName => AuthService.instance.currentUsername;

  // ── Search users by email ──

  Future<List<Map<String, dynamic>>> searchUsersByEmail(String email) async {
    try {
      final trimmed = email.trim().toLowerCase();
      if (trimmed.isEmpty) return [];

      final snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: trimmed)
          .limit(10)
          .get();

      return snapshot.docs
          .where((doc) => doc.id != _currentUid) // exclude self
          .map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'displayName': data['displayName'] ?? '',
          'email': data['email'] ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception('Kullanici aranamadi: $e');
    }
  }

  // ── Send friend request ──

  Future<({bool success, String message})> sendFriendRequest({
    required String toUid,
    required String toEmail,
  }) async {
    try {
      if (_currentUid == null) {
        return (success: false, message: 'Oturum acik degil');
      }

      // Check if already friends
      final existingFriend = await _db
          .collection('users')
          .doc(_currentUid)
          .collection('friends')
          .doc(toUid)
          .get();

      if (existingFriend.exists) {
        return (success: false, message: 'Bu kisi zaten arkadasiniz');
      }

      // Check if there's already a pending request in either direction
      final existingRequest1 = await _db
          .collection('friend_requests')
          .where('fromUid', isEqualTo: _currentUid)
          .where('toUid', isEqualTo: toUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest1.docs.isNotEmpty) {
        return (success: false, message: 'Zaten bekleyen bir istegi var');
      }

      final existingRequest2 = await _db
          .collection('friend_requests')
          .where('fromUid', isEqualTo: toUid)
          .where('toUid', isEqualTo: _currentUid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest2.docs.isNotEmpty) {
        return (success: false, message: 'Bu kisi size zaten istek gonderdi');
      }

      await _db.collection('friend_requests').add({
        'fromUid': _currentUid,
        'fromName': _currentName ?? '',
        'fromEmail': _currentEmail ?? '',
        'toUid': toUid,
        'toEmail': toEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return (success: true, message: 'Arkadaslik istegi gonderildi');
    } catch (e) {
      return (success: false, message: 'Istek gonderilemedi: $e');
    }
  }

  // ── Accept friend request ──

  Future<({bool success, String message})> acceptFriendRequest(FriendRequest request) async {
    try {
      if (_currentUid == null) {
        return (success: false, message: 'Oturum acik degil');
      }

      final batch = _db.batch();

      // Update request status
      batch.update(
        _db.collection('friend_requests').doc(request.id),
        {'status': 'accepted'},
      );

      // Add to current user's friends
      batch.set(
        _db.collection('users').doc(_currentUid).collection('friends').doc(request.fromUid),
        {
          'friendUid': request.fromUid,
          'friendName': request.fromName,
          'friendEmail': request.fromEmail,
          'addedAt': FieldValue.serverTimestamp(),
        },
      );

      // Add to sender's friends
      batch.set(
        _db.collection('users').doc(request.fromUid).collection('friends').doc(_currentUid),
        {
          'friendUid': _currentUid,
          'friendName': _currentName ?? '',
          'friendEmail': _currentEmail ?? '',
          'addedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      return (success: true, message: 'Arkadaslik istegi kabul edildi');
    } catch (e) {
      return (success: false, message: 'Istek kabul edilemedi: $e');
    }
  }

  // ── Reject friend request ──

  Future<({bool success, String message})> rejectFriendRequest(String requestId) async {
    try {
      await _db.collection('friend_requests').doc(requestId).update({
        'status': 'rejected',
      });
      return (success: true, message: 'Arkadaslik istegi reddedildi');
    } catch (e) {
      return (success: false, message: 'Istek reddedilemedi: $e');
    }
  }

  // ── Get friends list ──

  Future<List<FriendData>> getFriendsList() async {
    try {
      if (_currentUid == null) return [];

      final snapshot = await _db
          .collection('users')
          .doc(_currentUid)
          .collection('friends')
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FriendData.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Stream friends list (for real-time updates) ──

  Stream<List<FriendData>> friendsStream() {
    if (_currentUid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_currentUid)
        .collection('friends')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FriendData.fromMap(doc.data())).toList());
  }

  // ── Get pending requests ──

  Future<List<FriendRequest>> getPendingRequests() async {
    try {
      if (_currentUid == null) return [];

      final snapshot = await _db
          .collection('friend_requests')
          .where('toUid', isEqualTo: _currentUid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => FriendRequest.fromDoc(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Stream pending requests count ──

  Stream<int> pendingRequestCountStream() {
    if (_currentUid == null) return Stream.value(0);

    return _db
        .collection('friend_requests')
        .where('toUid', isEqualTo: _currentUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ── Get friend's public data ──

  Future<FriendPublicData> getFriendPublicData(String friendUid) async {
    try {
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Read daily data
      final dailyDoc = await _db
          .collection('users')
          .doc(friendUid)
          .collection('daily')
          .doc(dateKey)
          .get();

      int steps = 0;
      int water = 0;

      if (dailyDoc.exists) {
        final dailyData = dailyDoc.data() ?? {};
        steps = (dailyData['steps'] as int?) ?? 0;
        water = (dailyData['water'] as int?) ?? 0;
      }

      // Read risk checklist from settings
      final settingsDoc = await _db
          .collection('users')
          .doc(friendUid)
          .collection('settings')
          .doc('prefs')
          .get();

      int riskScore = 0;
      String riskLevel = 'Bilinmiyor';

      if (settingsDoc.exists) {
        final settingsData = settingsDoc.data() ?? {};
        final riskData = settingsData['riskChecklist'] as Map<String, dynamic>?;

        if (riskData != null) {
          riskScore = _calculateRiskScore(riskData);
          riskLevel = _getRiskLevel(riskScore);
        }
      }

      return FriendPublicData(
        steps: steps,
        water: water,
        riskScore: riskScore,
        riskLevel: riskLevel,
      );
    } catch (e) {
      return FriendPublicData(
        steps: 0,
        water: 0,
        riskScore: 0,
        riskLevel: 'Bilinmiyor',
      );
    }
  }

  // ── Unfriend ──

  Future<({bool success, String message})> unfriend(String friendUid) async {
    try {
      if (_currentUid == null) {
        return (success: false, message: 'Oturum acik degil');
      }

      final batch = _db.batch();

      batch.delete(
        _db.collection('users').doc(_currentUid).collection('friends').doc(friendUid),
      );
      batch.delete(
        _db.collection('users').doc(friendUid).collection('friends').doc(_currentUid),
      );

      await batch.commit();
      return (success: true, message: 'Arkadas silindi');
    } catch (e) {
      return (success: false, message: 'Arkadas silinemedi: $e');
    }
  }

  // ── Risk score calculation (same logic as RiskScreen) ──

  int _calculateRiskScore(Map<String, dynamic> data) {
    int score = 0;
    if (data['familyHistory'] == true) score += 20;
    if (data['smoking'] == true) score += 20;
    if (data['hypertension'] == true) score += 15;
    if (data['hyperlipidemia'] == true) score += 15;
    if (data['diabetes'] == true) score += 15;
    if (data['inactivity'] == true) score += 10;

    final height = (data['height'] as num?)?.toDouble() ?? 0;
    final weight = (data['weight'] as num?)?.toDouble() ?? 0;

    if (height > 0 && weight > 0) {
      final heightM = height / 100;
      final bmi = weight / (heightM * heightM);
      if (bmi >= 30) {
        score += 15;
      } else if (bmi >= 25) {
        score += 8;
      } else if (bmi < 18.5) {
        score += 5;
      }
    }

    return score.clamp(0, 100);
  }

  String _getRiskLevel(int score) {
    if (score >= 60) return 'Yuksek';
    if (score >= 35) return 'Orta';
    if (score > 0) return 'Dusuk';
    return 'Bilinmiyor';
  }
}
