import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'friends_service.dart';

// ── Data Classes ──

class ChallengeData {
  final String id;
  final String type; // 'steps' | 'water' | 'smoking'
  final String title;
  final String createdBy;
  final String createdByName;
  final String duration; // 'daily' | 'weekly'
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active' | 'completed'
  final List<Map<String, dynamic>> participants;
  final List<String> participantUids;
  final Map<String, dynamic>? winner;

  ChallengeData({
    required this.id,
    required this.type,
    required this.title,
    required this.createdBy,
    required this.createdByName,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.participants,
    required this.participantUids,
    this.winner,
  });

  factory ChallengeData.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeData(
      id: doc.id,
      type: data['type'] ?? 'steps',
      title: data['title'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
      duration: data['duration'] ?? 'daily',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
      participants: List<Map<String, dynamic>>.from(data['participants'] ?? []),
      participantUids: List<String>.from(data['participantUids'] ?? []),
      winner: data['winner'] as Map<String, dynamic>?,
    );
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return Duration.zero;
    return endDate.difference(now);
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
}

class LeaderboardEntry {
  final String uid;
  final String name;
  final int score;
  final int rank;

  LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.score,
    required this.rank,
  });
}

// ── Service ──

class ChallengeService {
  static final ChallengeService instance = ChallengeService._();
  ChallengeService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _currentUid => AuthService.instance.currentUserId;
  String? get _currentName => AuthService.instance.currentUsername;
  String? get _currentEmail => AuthService.instance.currentEmail;

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ── Create Challenge ──

  Future<({bool success, String message})> createChallenge({
    required String type,
    required String title,
    required String duration,
    required List<String> friendUids,
  }) async {
    try {
      if (_currentUid == null) {
        return (success: false, message: 'Oturum acik degil');
      }

      if (friendUids.isEmpty) {
        return (success: false, message: 'En az bir arkadas secmelisiniz');
      }

      // Build participants list: include current user + selected friends
      final friends = await FriendsService.instance.getFriendsList();
      final participants = <Map<String, dynamic>>[
        {'uid': _currentUid, 'name': _currentName ?? '', 'email': _currentEmail ?? ''},
      ];
      final participantUids = <String>[_currentUid!];

      for (final friendUid in friendUids) {
        final friend = friends.where((f) => f.uid == friendUid).firstOrNull;
        if (friend != null) {
          participants.add({
            'uid': friend.uid,
            'name': friend.name,
            'email': friend.email,
          });
          participantUids.add(friend.uid);
        }
      }

      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = duration == 'daily'
          ? startDate.add(const Duration(days: 1))
          : startDate.add(const Duration(days: 7));

      await _db.collection('challenges').add({
        'type': type,
        'title': title,
        'createdBy': _currentUid,
        'createdByName': _currentName ?? '',
        'duration': duration,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'active',
        'participants': participants,
        'participantUids': participantUids,
        'winner': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return (success: true, message: 'Challenge olusturuldu!');
    } catch (e) {
      return (success: false, message: 'Challenge olusturulamadi: $e');
    }
  }

  // ── Get Active Challenges ──

  Future<List<ChallengeData>> getActiveChallenges() async {
    try {
      if (_currentUid == null) return [];

      final snapshot = await _db
          .collection('challenges')
          .where('participantUids', arrayContains: _currentUid)
          .where('status', isEqualTo: 'active')
          .orderBy('startDate', descending: true)
          .get();

      return snapshot.docs.map((doc) => ChallengeData.fromDoc(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Get Completed Challenges ──

  Future<List<ChallengeData>> getCompletedChallenges() async {
    try {
      if (_currentUid == null) return [];

      final snapshot = await _db
          .collection('challenges')
          .where('participantUids', arrayContains: _currentUid)
          .where('status', isEqualTo: 'completed')
          .orderBy('endDate', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => ChallengeData.fromDoc(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ── Get Challenge Leaderboard ──

  Future<List<LeaderboardEntry>> getChallengeLeaderboard(ChallengeData challenge) async {
    try {
      final entries = <LeaderboardEntry>[];
      final now = DateTime.now();
      final effectiveEnd = challenge.endDate.isBefore(now) ? challenge.endDate : now;

      for (final participant in challenge.participants) {
        final uid = participant['uid'] as String? ?? '';
        final name = participant['name'] as String? ?? '';
        int score = 0;

        switch (challenge.type) {
          case 'steps':
            score = await _getStepsScore(uid, challenge.startDate, effectiveEnd);
            break;
          case 'water':
            score = await _getWaterScore(uid, challenge.startDate, effectiveEnd);
            break;
          case 'smoking':
            score = await _getSmokingScore(uid);
            break;
        }

        entries.add(LeaderboardEntry(uid: uid, name: name, score: score, rank: 0));
      }

      // Sort by score descending
      entries.sort((a, b) => b.score.compareTo(a.score));

      // Assign ranks
      final ranked = <LeaderboardEntry>[];
      for (int i = 0; i < entries.length; i++) {
        ranked.add(LeaderboardEntry(
          uid: entries[i].uid,
          name: entries[i].name,
          score: entries[i].score,
          rank: i + 1,
        ));
      }

      return ranked;
    } catch (e) {
      return [];
    }
  }

  Future<int> _getStepsScore(String uid, DateTime start, DateTime end) async {
    int totalSteps = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDay)) {
      try {
        final doc = await _db
            .collection('users')
            .doc(uid)
            .collection('daily')
            .doc(_dateKey(current))
            .get();

        if (doc.exists) {
          totalSteps += ((doc.data()?['steps'] as num?) ?? 0).toInt();
        }
      } catch (_) {}
      current = current.add(const Duration(days: 1));
    }

    return totalSteps;
  }

  Future<int> _getWaterScore(String uid, DateTime start, DateTime end) async {
    int daysHitGoal = 0;

    // Get user's water goal
    int waterGoal = 14;
    try {
      final settingsDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('prefs')
          .get();
      if (settingsDoc.exists) {
        waterGoal = ((settingsDoc.data()?['waterGoal'] as num?) ?? 14).toInt();
      }
    } catch (_) {}

    DateTime current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(endDay)) {
      try {
        final doc = await _db
            .collection('users')
            .doc(uid)
            .collection('daily')
            .doc(_dateKey(current))
            .get();

        if (doc.exists) {
          final water = ((doc.data()?['water'] as num?) ?? 0).toInt();
          if (water >= waterGoal) daysHitGoal++;
        }
      } catch (_) {}
      current = current.add(const Duration(days: 1));
    }

    return daysHitGoal;
  }

  Future<int> _getSmokingScore(String uid) async {
    try {
      final settingsDoc = await _db
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('prefs')
          .get();

      if (settingsDoc.exists) {
        final quitDateStr = settingsDoc.data()?['smokingQuitDate'] as String?;
        if (quitDateStr != null) {
          final quitDate = DateTime.tryParse(quitDateStr);
          if (quitDate != null) {
            final daysFree = DateTime.now().difference(quitDate).inDays;
            return daysFree > 0 ? daysFree : 0;
          }
        }
      }
    } catch (_) {}
    return 0;
  }

  // ── Check and Complete Expired Challenges ──

  /// Returns list of (challenge title, winner uid) for challenges that just completed.
  Future<List<({String title, String? winnerUid})>> checkAndCompleteExpiredChallenges() async {
    final results = <({String title, String? winnerUid})>[];
    try {
      if (_currentUid == null) return [];

      final snapshot = await _db
          .collection('challenges')
          .where('participantUids', arrayContains: _currentUid)
          .where('status', isEqualTo: 'active')
          .get();

      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final challenge = ChallengeData.fromDoc(doc);
        if (challenge.endDate.isBefore(now)) {
          // Determine winner
          final leaderboard = await getChallengeLeaderboard(challenge);
          Map<String, dynamic>? winnerData;
          String? winnerUid;

          if (leaderboard.isNotEmpty) {
            final winner = leaderboard.first;
            winnerData = {
              'uid': winner.uid,
              'name': winner.name,
              'score': winner.score,
            };
            winnerUid = winner.uid;
          }

          await _db.collection('challenges').doc(challenge.id).update({
            'status': 'completed',
            'winner': winnerData,
          });

          results.add((title: challenge.title, winnerUid: winnerUid));
        }
      }
    } catch (_) {}
    return results;
  }

  // ── Delete Challenge ──

  Future<({bool success, String message})> deleteChallenge(String challengeId) async {
    try {
      if (_currentUid == null) {
        return (success: false, message: 'Oturum acik degil');
      }

      final doc = await _db.collection('challenges').doc(challengeId).get();
      if (!doc.exists) {
        return (success: false, message: 'Challenge bulunamadi');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['createdBy'] != _currentUid) {
        return (success: false, message: 'Sadece olusturan kisi silebilir');
      }

      await _db.collection('challenges').doc(challengeId).delete();
      return (success: true, message: 'Challenge silindi');
    } catch (e) {
      return (success: false, message: 'Challenge silinemedi: $e');
    }
  }

  // ── Leave Challenge ──

  Future<({bool success, String message})> leaveChallenge(String challengeId) async {
    try {
      if (_currentUid == null) {
        return (success: false, message: 'Oturum acik degil');
      }

      final doc = await _db.collection('challenges').doc(challengeId).get();
      if (!doc.exists) {
        return (success: false, message: 'Challenge bulunamadi');
      }

      final data = doc.data() as Map<String, dynamic>;
      final participants = List<Map<String, dynamic>>.from(data['participants'] ?? []);
      final participantUids = List<String>.from(data['participantUids'] ?? []);

      participants.removeWhere((p) => p['uid'] == _currentUid);
      participantUids.remove(_currentUid);

      if (participantUids.isEmpty) {
        // No one left, delete the challenge
        await _db.collection('challenges').doc(challengeId).delete();
      } else {
        await _db.collection('challenges').doc(challengeId).update({
          'participants': participants,
          'participantUids': participantUids,
        });
      }

      return (success: true, message: 'Challenge\'dan ayrildiniz');
    } catch (e) {
      return (success: false, message: 'Ayrilamadi: $e');
    }
  }

  // ── Stream: Active Challenge Count ──

  Stream<int> activeChallengeCountStream() {
    if (_currentUid == null) return Stream.value(0);

    return _db
        .collection('challenges')
        .where('participantUids', arrayContains: _currentUid)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
