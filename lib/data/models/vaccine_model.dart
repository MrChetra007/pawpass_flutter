enum VaccineStatus { upToDate, dueSoon, overdue, unknown }

class Vaccine {
  final String id;
  final String petId;
  final String userId;
  final String name;
  final DateTime dateGiven;
  final DateTime? nextDueDate;
  final String? vetName;
  final String? clinicName;
  final String? batchNumber;
  final String? docUrl;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Vaccine({
    required this.id,
    required this.petId,
    required this.userId,
    required this.name,
    required this.dateGiven,
    this.nextDueDate,
    this.vetName,
    this.clinicName,
    this.batchNumber,
    this.docUrl,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Vaccine.fromJson(Map<String, dynamic> json) {
    return Vaccine(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      dateGiven: DateTime.parse(json['date_given'] as String),
      nextDueDate: json['next_due_date'] != null ? DateTime.parse(json['next_due_date'] as String) : null,
      vetName: json['vet_name'] as String?,
      clinicName: json['clinic_name'] as String?,
      batchNumber: json['batch_number'] as String?,
      docUrl: json['doc_url'] as String?,
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
      'date_given': dateGiven.toIso8601String().split('T').first,
      if (nextDueDate != null) 'next_due_date': nextDueDate!.toIso8601String().split('T').first,
      if (vetName != null) 'vet_name': vetName,
      if (clinicName != null) 'clinic_name': clinicName,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (docUrl != null) 'doc_url': docUrl,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
    };
  }

  VaccineStatus get status {
    if (nextDueDate == null) return VaccineStatus.unknown;
    final now = DateTime.now();
    if (nextDueDate!.isBefore(now)) return VaccineStatus.overdue;
    if (nextDueDate!.difference(now).inDays <= 30) return VaccineStatus.dueSoon;
    return VaccineStatus.upToDate;
  }

  String get statusLabel {
    switch (status) {
      case VaccineStatus.upToDate: return 'Up to date';
      case VaccineStatus.dueSoon: return 'Due soon';
      case VaccineStatus.overdue: return 'Overdue';
      case VaccineStatus.unknown: return 'Unknown';
    }
  }
}
