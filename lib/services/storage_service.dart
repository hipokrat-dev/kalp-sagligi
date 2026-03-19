import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_data.dart';
import 'auth_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  static StorageService get instance => _instance;
  StorageService._();

  late SharedPreferences _prefs;
  bool _initialized = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  // Firestore doc reference for current user
  DocumentReference? get _userDoc {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  CollectionReference? get _dailyCol {
    return _userDoc?.collection('daily');
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ── Helper: get/set with Firestore sync ──

  Future<Map<String, dynamic>> _getDailyData(DateTime date) async {
    await _ensureInitialized();
    final key = _dateKey(date);

    // Try Firestore first
    try {
      final doc = await _dailyCol?.doc(key).get();
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        // Cache locally
        _prefs.setString('cache_daily_$key', jsonEncode(data));
        return data;
      }
    } catch (_) {}

    // Fallback to local cache
    final cached = _prefs.getString('cache_daily_$key');
    if (cached != null) return Map<String, dynamic>.from(jsonDecode(cached));
    return {};
  }

  Future<void> _updateDailyData(DateTime date, Map<String, dynamic> updates) async {
    await _ensureInitialized();
    final key = _dateKey(date);

    // Update local cache
    final current = await _getDailyData(date);
    current.addAll(updates);
    _prefs.setString('cache_daily_$key', jsonEncode(current));

    // Sync to Firestore
    try {
      await _dailyCol?.doc(key).set(updates, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _getUserSettings() async {
    await _ensureInitialized();

    try {
      final doc = await _userDoc?.collection('settings').doc('prefs').get();
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _prefs.setString('cache_settings', jsonEncode(data));
        return data;
      }
    } catch (_) {}

    final cached = _prefs.getString('cache_settings');
    if (cached != null) return Map<String, dynamic>.from(jsonDecode(cached));
    return {};
  }

  Future<void> _updateUserSettings(Map<String, dynamic> updates) async {
    await _ensureInitialized();

    final current = await _getUserSettings();
    current.addAll(updates);
    _prefs.setString('cache_settings', jsonEncode(current));

    try {
      await _userDoc?.collection('settings').doc('prefs').set(updates, SetOptions(merge: true));
    } catch (_) {}
  }

  // ── Steps ──

  Future<int> getSteps(DateTime date) async {
    final data = await _getDailyData(date);
    return (data['steps'] as int?) ?? 0;
  }

  Future<void> setSteps(DateTime date, int steps) async {
    await _updateDailyData(date, {'steps': steps});
  }

  // ── Water ──

  Future<int> getWaterGlasses(DateTime date) async {
    final data = await _getDailyData(date);
    return (data['water'] as int?) ?? 0;
  }

  Future<void> setWaterGlasses(DateTime date, int glasses) async {
    await _updateDailyData(date, {'water': glasses});
  }

  // ── Blood Pressure ──

  Future<List<BloodPressureRecord>> getBloodPressureRecords() async {
    try {
      final snapshot = await _userDoc
          ?.collection('blood_pressure')
          .orderBy('date', descending: true)
          .limit(100)
          .get();

      if (snapshot != null && snapshot.docs.isNotEmpty) {
        final records = snapshot.docs
            .map((d) => BloodPressureRecord.fromJson(d.data()))
            .toList();
        // Cache locally
        await _ensureInitialized();
        _prefs.setString('cache_bp', jsonEncode(records.map((e) => e.toJson()).toList()));
        return records;
      }
    } catch (_) {}

    // Fallback to local cache
    await _ensureInitialized();
    final cached = _prefs.getString('cache_bp');
    if (cached != null) {
      final list = jsonDecode(cached) as List;
      return list.map((e) => BloodPressureRecord.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> addBloodPressureRecord(BloodPressureRecord record) async {
    try {
      await _userDoc?.collection('blood_pressure').add(record.toJson());
    } catch (_) {}

    // Update local cache
    await _ensureInitialized();
    final records = await getBloodPressureRecords();
    records.insert(0, record);
    _prefs.setString('cache_bp', jsonEncode(records.map((e) => e.toJson()).toList()));
  }

  Future<void> deleteBloodPressureRecord(int index) async {
    try {
      final snapshot = await _userDoc
          ?.collection('blood_pressure')
          .orderBy('date', descending: true)
          .limit(100)
          .get();

      if (snapshot != null && index < snapshot.docs.length) {
        await snapshot.docs[index].reference.delete();
      }
    } catch (_) {}

    await _ensureInitialized();
    final records = await getBloodPressureRecords();
    if (index < records.length) {
      records.removeAt(index);
      _prefs.setString('cache_bp', jsonEncode(records.map((e) => e.toJson()).toList()));
    }
  }

  // ── Nutrition ──

  Future<List<NutritionEntry>> getNutritionEntries(DateTime date) async {
    final data = await _getDailyData(date);
    final list = data['nutrition'] as List?;
    if (list == null) return [];
    return list.map((e) => NutritionEntry.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> addNutritionEntry(DateTime date, NutritionEntry entry) async {
    final entries = await getNutritionEntries(date);
    entries.add(entry);
    await _updateDailyData(date, {
      'nutrition': entries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> deleteNutritionEntry(DateTime date, int index) async {
    final entries = await getNutritionEntries(date);
    if (index < entries.length) {
      entries.removeAt(index);
      await _updateDailyData(date, {
        'nutrition': entries.map((e) => e.toJson()).toList(),
      });
    }
  }

  // ── Smoking ──

  Future<DateTime?> getSmokingQuitDate() async {
    final settings = await _getUserSettings();
    final dateStr = settings['smokingQuitDate'] as String?;
    return dateStr != null ? DateTime.tryParse(dateStr) : null;
  }

  Future<void> setSmokingQuitDate(DateTime date) async {
    await _updateUserSettings({'smokingQuitDate': date.toIso8601String()});
  }

  Future<void> clearSmokingQuitDate() async {
    await _updateUserSettings({'smokingQuitDate': FieldValue.delete()});
    await _ensureInitialized();
    final current = await _getUserSettings();
    current.remove('smokingQuitDate');
    _prefs.setString('cache_settings', jsonEncode(current));
  }

  Future<int> getDailySmokingCount() async {
    final s = await _getUserSettings();
    return (s['dailySmokingCount'] as int?) ?? 20;
  }

  Future<void> setDailySmokingCount(int count) async {
    await _updateUserSettings({'dailySmokingCount': count});
  }

  Future<double> getPackPrice() async {
    final s = await _getUserSettings();
    return (s['packPrice'] as num?)?.toDouble() ?? 60.0;
  }

  Future<void> setPackPrice(double price) async {
    await _updateUserSettings({'packPrice': price});
  }

  // ── Goals ──

  Future<int> getStepGoal() async {
    final s = await _getUserSettings();
    return (s['stepGoal'] as int?) ?? 10000;
  }

  Future<void> setStepGoal(int goal) async {
    await _updateUserSettings({'stepGoal': goal});
  }

  Future<int> getWaterGoal() async {
    final s = await _getUserSettings();
    return (s['waterGoal'] as int?) ?? 14;
  }

  Future<void> setWaterGoal(int goal) async {
    await _updateUserSettings({'waterGoal': goal});
  }

  Future<int> getCalorieGoal() async {
    final s = await _getUserSettings();
    return (s['calorieGoal'] as int?) ?? 2000;
  }

  Future<void> setCalorieGoal(int goal) async {
    await _updateUserSettings({'calorieGoal': goal});
  }

  Future<double> getTargetWeight() async {
    final s = await _getUserSettings();
    return (s['targetWeight'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> setTargetWeight(double weight) async {
    await _updateUserSettings({'targetWeight': weight});
  }

  // ── Sleep ──

  Future<Map<String, dynamic>?> getSleep(DateTime date) async {
    final data = await _getDailyData(date);
    final quality = data['sleepQuality'] as int?;
    final hours = (data['sleepHours'] as num?)?.toDouble();
    if (quality == null) return null;
    return {'quality': quality, 'hours': hours ?? 0.0};
  }

  Future<void> setSleep(DateTime date, int quality, double hours) async {
    await _updateDailyData(date, {'sleepQuality': quality, 'sleepHours': hours});
  }

  Future<Map<String, Map<String, dynamic>>> getSleepHistory(int days) async {
    final map = <String, Map<String, dynamic>>{};
    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final sleep = await getSleep(date);
      if (sleep != null) map[_dateKey(date)] = sleep;
    }
    return map;
  }

  // ── Reminder settings ──

  Future<int> getReminderInterval(String type) async {
    final s = await _getUserSettings();
    return (s['reminder_${type}_minutes'] as int?) ??
        (type == 'water' ? 120 : type == 'movement' ? 60 : 480);
  }

  Future<void> setReminderInterval(String type, int minutes) async {
    await _updateUserSettings({'reminder_${type}_minutes': minutes});
  }

  Future<bool> getReminderEnabled(String type) async {
    final s = await _getUserSettings();
    return (s['reminder_${type}_enabled'] as bool?) ?? true;
  }

  Future<void> setReminderEnabled(String type, bool enabled) async {
    await _updateUserSettings({'reminder_${type}_enabled': enabled});
  }

  Future<String> getReminderStartTime(String type) async {
    final s = await _getUserSettings();
    return (s['reminder_${type}_start'] as String?) ?? '08:00';
  }

  Future<void> setReminderStartTime(String type, String time) async {
    await _updateUserSettings({'reminder_${type}_start': time});
  }

  Future<String> getReminderEndTime(String type) async {
    final s = await _getUserSettings();
    return (s['reminder_${type}_end'] as String?) ?? '22:00';
  }

  Future<void> setReminderEndTime(String type, String time) async {
    await _updateUserSettings({'reminder_${type}_end': time});
  }

  // ── Health Connect ──

  Future<bool> getHealthConnectEnabled() async {
    final s = await _getUserSettings();
    return (s['healthConnectEnabled'] as bool?) ?? false;
  }

  Future<void> setHealthConnectEnabled(bool enabled) async {
    await _updateUserSettings({'healthConnectEnabled': enabled});
  }

  // ── Mood ──

  Future<int?> getMood(DateTime date) async {
    final data = await _getDailyData(date);
    return data['mood'] as int?;
  }

  Future<void> setMood(DateTime date, int mood) async {
    await _updateDailyData(date, {'mood': mood});
  }

  Future<Map<String, int>> getMoodHistory(int days) async {
    final map = <String, int>{};
    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final mood = await getMood(date);
      if (mood != null) map[_dateKey(date)] = mood;
    }
    return map;
  }

  // ── Risk Checklist ──

  Future<Map<String, dynamic>> getRiskChecklist() async {
    final s = await _getUserSettings();
    final data = s['riskChecklist'] as Map<String, dynamic>?;
    if (data != null) return Map<String, dynamic>.from(data);
    return {
      'familyHistory': false,
      'smoking': false,
      'hypertension': false,
      'hyperlipidemia': false,
      'diabetes': false,
      'inactivity': false,
      'height': 0.0,
      'weight': 0.0,
    };
  }

  Future<void> saveRiskChecklist(Map<String, dynamic> data) async {
    await _updateUserSettings({'riskChecklist': data});
  }

  // ── Steps history ──

  Future<Map<String, int>> getStepsHistory(int days) async {
    final map = <String, int>{};
    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      map[_dateKey(date)] = await getSteps(date);
    }
    return map;
  }
}
