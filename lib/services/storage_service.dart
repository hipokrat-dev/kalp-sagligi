import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_data.dart';
import 'auth_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  static StorageService get instance => _instance;
  StorageService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  String get _prefix {
    final userId = AuthService.instance.currentUserId;
    return userId != null ? 'u_${userId}_' : '';
  }

  String _key(String key) => '$_prefix$key';

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Steps
  Future<int> getSteps(DateTime date) async {
    await _ensureInitialized();
    return _prefs.getInt(_key('steps_${_dateKey(date)}')) ?? 0;
  }

  Future<void> setSteps(DateTime date, int steps) async {
    await _ensureInitialized();
    await _prefs.setInt(_key('steps_${_dateKey(date)}'), steps);
  }

  // Water
  Future<int> getWaterGlasses(DateTime date) async {
    await _ensureInitialized();
    return _prefs.getInt(_key('water_${_dateKey(date)}')) ?? 0;
  }

  Future<void> setWaterGlasses(DateTime date, int glasses) async {
    await _ensureInitialized();
    await _prefs.setInt(_key('water_${_dateKey(date)}'), glasses);
  }

  // Blood Pressure
  Future<List<BloodPressureRecord>> getBloodPressureRecords() async {
    await _ensureInitialized();
    final data = _prefs.getString(_key('bp_records'));
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => BloodPressureRecord.fromJson(e)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addBloodPressureRecord(BloodPressureRecord record) async {
    await _ensureInitialized();
    final records = await getBloodPressureRecords();
    records.insert(0, record);
    await _prefs.setString(
      _key('bp_records'),
      jsonEncode(records.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteBloodPressureRecord(int index) async {
    await _ensureInitialized();
    final records = await getBloodPressureRecords();
    if (index < records.length) {
      records.removeAt(index);
      await _prefs.setString(
        _key('bp_records'),
        jsonEncode(records.map((e) => e.toJson()).toList()),
      );
    }
  }

  // Nutrition
  Future<List<NutritionEntry>> getNutritionEntries(DateTime date) async {
    await _ensureInitialized();
    final data = _prefs.getString(_key('nutrition_${_dateKey(date)}'));
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => NutritionEntry.fromJson(e)).toList();
  }

  Future<void> addNutritionEntry(DateTime date, NutritionEntry entry) async {
    await _ensureInitialized();
    final entries = await getNutritionEntries(date);
    entries.add(entry);
    await _prefs.setString(
      _key('nutrition_${_dateKey(date)}'),
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> deleteNutritionEntry(DateTime date, int index) async {
    await _ensureInitialized();
    final entries = await getNutritionEntries(date);
    if (index < entries.length) {
      entries.removeAt(index);
      await _prefs.setString(
        _key('nutrition_${_dateKey(date)}'),
        jsonEncode(entries.map((e) => e.toJson()).toList()),
      );
    }
  }

  // Smoking Cessation
  Future<DateTime?> getSmokingQuitDate() async {
    await _ensureInitialized();
    final dateStr = _prefs.getString(_key('smoking_quit_date'));
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  Future<void> setSmokingQuitDate(DateTime date) async {
    await _ensureInitialized();
    await _prefs.setString(_key('smoking_quit_date'), date.toIso8601String());
  }

  Future<void> clearSmokingQuitDate() async {
    await _ensureInitialized();
    await _prefs.remove(_key('smoking_quit_date'));
  }

  Future<int> getDailySmokingCount() async {
    await _ensureInitialized();
    return _prefs.getInt(_key('daily_smoking_count')) ?? 20;
  }

  Future<void> setDailySmokingCount(int count) async {
    await _ensureInitialized();
    await _prefs.setInt(_key('daily_smoking_count'), count);
  }

  Future<double> getPackPrice() async {
    await _ensureInitialized();
    return _prefs.getDouble(_key('pack_price')) ?? 60.0;
  }

  Future<void> setPackPrice(double price) async {
    await _ensureInitialized();
    await _prefs.setDouble(_key('pack_price'), price);
  }

  // Step goal
  Future<int> getStepGoal() async {
    await _ensureInitialized();
    return _prefs.getInt(_key('step_goal')) ?? 10000;
  }

  Future<void> setStepGoal(int goal) async {
    await _ensureInitialized();
    await _prefs.setInt(_key('step_goal'), goal);
  }

  // Water goal
  Future<int> getWaterGoal() async {
    await _ensureInitialized();
    return _prefs.getInt(_key('water_goal')) ?? 8;
  }

  Future<void> setWaterGoal(int goal) async {
    await _ensureInitialized();
    await _prefs.setInt(_key('water_goal'), goal);
  }

  // Calorie goal
  Future<int> getCalorieGoal() async {
    await _ensureInitialized();
    return _prefs.getInt(_key('calorie_goal')) ?? 2000;
  }

  Future<void> setCalorieGoal(int goal) async {
    await _ensureInitialized();
    await _prefs.setInt(_key('calorie_goal'), goal);
  }

  // Risk Checklist
  Future<Map<String, dynamic>> getRiskChecklist() async {
    await _ensureInitialized();
    final data = _prefs.getString(_key('risk_checklist'));
    if (data == null) {
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
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  Future<void> saveRiskChecklist(Map<String, dynamic> data) async {
    await _ensureInitialized();
    await _prefs.setString(_key('risk_checklist'), jsonEncode(data));
  }

  // Steps history (last 7 days)
  Future<Map<String, int>> getStepsHistory(int days) async {
    await _ensureInitialized();
    final map = <String, int>{};
    for (int i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      map[_dateKey(date)] = await getSteps(date);
    }
    return map;
  }
}
