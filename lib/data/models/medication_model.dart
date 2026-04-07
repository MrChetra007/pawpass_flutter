class Medication {
  final String id;
  final String petId;
  final String userId;
  final String name;
  final String? dosage;
  final String? frequency;
  final String? mealTiming;
  final String? frequencyType;
  final int? frequencyTimes;
  final List<String> timeOfDay;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? prescribedBy;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Medication({
    required this.id,
    required this.petId,
    required this.userId,
    required this.name,
    this.dosage,
    this.frequency,
    this.mealTiming,
    this.frequencyType,
    this.frequencyTimes,
    this.timeOfDay = const [],
    this.startDate,
    this.endDate,
    this.prescribedBy,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      mealTiming: json['meal_timing'] as String?,
      frequencyType: json['frequency_type'] as String?,
      frequencyTimes: json['frequency_times'] as int?,
      timeOfDay: (json['time_of_day'] as List<dynamic>?)?.cast<String>() ?? [],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      prescribedBy: json['prescribed_by'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'user_id': userId,
      'name': name,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (mealTiming != null) 'meal_timing': mealTiming,
      if (frequencyType != null) 'frequency_type': frequencyType,
      if (frequencyTimes != null) 'frequency_times': frequencyTimes,
      if (timeOfDay.isNotEmpty) 'time_of_day': timeOfDay,
      if (startDate != null) 'start_date': startDate!.toIso8601String().split('T').first,
      if (endDate != null) 'end_date': endDate!.toIso8601String().split('T').first,
      if (prescribedBy != null) 'prescribed_by': prescribedBy,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
    };
  }

  String get frequencyLabel {
    switch (frequency?.toLowerCase()) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'monthly': return 'Monthly';
      case 'as needed': return 'As Needed';
      default: return frequency ?? 'Custom';
    }
  }

  String get mealTimingLabel {
    switch (mealTiming) {
      case 'before_meal': return 'Before Meal';
      case 'after_meal': return 'After Meal';
      case 'with_meal': return 'With Meal';
      default: return 'Any';
    }
  }

  String get timeOfDayLabel {
    if (timeOfDay.isEmpty) return '';
    final labels = <String>[];
    if (timeOfDay.contains('morning')) labels.add('Morning');
    if (timeOfDay.contains('afternoon')) labels.add('Afternoon');
    if (timeOfDay.contains('evening')) labels.add('Evening');
    if (timeOfDay.contains('night')) labels.add('Night');
    return labels.join(', ');
  }
}
