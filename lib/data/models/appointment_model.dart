class Appointment {
  final String id;
  final String petId;
  final String userId;
  final String title;
  final String? type;
  final DateTime datetime;
  final String? vetName;
  final String? clinicName;
  final String? clinicPhone;
  final String? clinicAddress;
  final String? notes;
  final bool reminderSent;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.id,
    required this.petId,
    required this.userId,
    required this.title,
    this.type,
    required this.datetime,
    this.vetName,
    this.clinicName,
    this.clinicPhone,
    this.clinicAddress,
    this.notes,
    this.reminderSent = false,
    this.status = 'upcoming',
    required this.createdAt,
    this.updatedAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      type: json['type'] as String?,
      datetime: DateTime.parse(json['datetime'] as String),
      vetName: json['vet_name'] as String?,
      clinicName: json['clinic_name'] as String?,
      clinicPhone: json['clinic_phone'] as String?,
      clinicAddress: json['clinic_address'] as String?,
      notes: json['notes'] as String?,
      reminderSent: json['reminder_sent'] as bool? ?? false,
      status: json['status'] as String? ?? 'upcoming',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'user_id': userId,
      'title': title,
      if (type != null) 'type': type,
      'datetime': datetime.toIso8601String(),
      if (vetName != null) 'vet_name': vetName,
      if (clinicName != null) 'clinic_name': clinicName,
      if (clinicPhone != null) 'clinic_phone': clinicPhone,
      if (clinicAddress != null) 'clinic_address': clinicAddress,
      if (notes != null) 'notes': notes,
      'reminder_sent': reminderSent,
      'status': status,
    };
  }

  String get typeLabel {
    switch (type) {
      case 'vet': return 'Vet Visit';
      case 'grooming': return 'Grooming';
      case 'training': return 'Training';
      default: return 'Other';
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'vet': return '🩺';
      case 'grooming': return '✂️';
      case 'training': return '🎓';
      default: return '📅';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'upcoming': return 'Upcoming';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }
}
