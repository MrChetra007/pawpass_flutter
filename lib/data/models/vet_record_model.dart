class VetRecord {
  final String id;
  final String petId;
  final String userId;
  final String type;
  final String title;
  final DateTime date;
  final String? vetName;
  final String? clinicName;
  final String? diagnosis;
  final String? treatment;
  final String? notes;
  final String? docUrl;
  final double? cost;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VetRecord({
    required this.id,
    required this.petId,
    required this.userId,
    required this.type,
    required this.title,
    required this.date,
    this.vetName,
    this.clinicName,
    this.diagnosis,
    this.treatment,
    this.notes,
    this.docUrl,
    this.cost,
    required this.createdAt,
    this.updatedAt,
  });

  factory VetRecord.fromJson(Map<String, dynamic> json) {
    return VetRecord(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      vetName: json['vet_name'] as String?,
      clinicName: json['clinic_name'] as String?,
      diagnosis: json['diagnosis'] as String?,
      treatment: json['treatment'] as String?,
      notes: json['notes'] as String?,
      docUrl: json['doc_url'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'user_id': userId,
      'type': type,
      'title': title,
      'date': date.toIso8601String().split('T').first,
      if (vetName != null) 'vet_name': vetName,
      if (clinicName != null) 'clinic_name': clinicName,
      if (diagnosis != null) 'diagnosis': diagnosis,
      if (treatment != null) 'treatment': treatment,
      if (notes != null) 'notes': notes,
      if (docUrl != null) 'doc_url': docUrl,
      if (cost != null) 'cost': cost,
    };
  }

  String get typeLabel {
    switch (type) {
      case 'checkup': return 'Checkup';
      case 'surgery': return 'Surgery';
      case 'illness': return 'Illness';
      case 'injury': return 'Injury';
      case 'dental': return 'Dental';
      case 'grooming': return 'Grooming';
      case 'lab_result': return 'Lab Result';
      default: return 'Other';
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'checkup': return '🩺';
      case 'surgery': return '💉';
      case 'illness': return '🤒';
      case 'injury': return '🩹';
      case 'dental': return '🦷';
      case 'grooming': return '✨';
      case 'lab_result': return '🧪';
      default: return '📋';
    }
  }
}
