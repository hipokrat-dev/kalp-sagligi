class BloodPressureRecord {
  final DateTime date;
  final int systolic;
  final int diastolic;
  final int pulse;
  final String? note;

  BloodPressureRecord({
    required this.date,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'systolic': systolic,
    'diastolic': diastolic,
    'pulse': pulse,
    'note': note,
  };

  factory BloodPressureRecord.fromJson(Map<String, dynamic> json) {
    return BloodPressureRecord(
      date: DateTime.parse(json['date']),
      systolic: json['systolic'],
      diastolic: json['diastolic'],
      pulse: json['pulse'],
      note: json['note'],
    );
  }

  String get riskLevel {
    if (systolic >= 180 || diastolic >= 120) return 'Kriz';
    if (systolic >= 140 || diastolic >= 90) return 'Yüksek';
    if (systolic >= 130 || diastolic >= 80) return 'Yükselmiş';
    if (systolic >= 120 && diastolic < 80) return 'Normal Üstü';
    return 'Normal';
  }

  String get pulseStatus {
    if (pulse < 60) return 'Düşük';
    if (pulse > 100) return 'Yüksek';
    return 'Normal';
  }
}

class NutritionEntry {
  final DateTime date;
  final String meal;
  final String description;
  final int calories;

  NutritionEntry({
    required this.date,
    required this.meal,
    required this.description,
    required this.calories,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'meal': meal,
    'description': description,
    'calories': calories,
  };

  factory NutritionEntry.fromJson(Map<String, dynamic> json) {
    return NutritionEntry(
      date: DateTime.parse(json['date']),
      meal: json['meal'],
      description: json['description'],
      calories: json['calories'],
    );
  }
}
