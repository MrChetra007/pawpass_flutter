class WeightLog {
  final String id;
  final String petId;
  final String userId;
  final double weightKg;
  final DateTime recordedAt;
  final String? notes;
  final DateTime createdAt;

  WeightLog({
    required this.id,
    required this.petId,
    required this.userId,
    required this.weightKg,
    required this.recordedAt,
    this.notes,
    required this.createdAt,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) {
    return WeightLog(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      weightKg: (json['weight_kg'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'user_id': userId,
      'weight_kg': weightKg,
      'recorded_at': recordedAt.toIso8601String().split('T').first,
      if (notes != null) 'notes': notes,
    };
  }

  double get weightLbs => weightKg * 2.20462;
}
