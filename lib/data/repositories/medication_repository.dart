import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/medication_model.dart';

class MedicationRepository {
  final SupabaseClient _supabase;

  MedicationRepository(this._supabase);

  Future<List<Medication>> getMedications({
    String? petId,
    bool? activeOnly,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('medications')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    var medications = (response as List)
        .map((json) => Medication.fromJson(json as Map<String, dynamic>))
        .toList();

    if (petId != null) {
      medications = medications.where((m) => m.petId == petId).toList();
    }

    if (activeOnly == true) {
      medications = medications.where((m) => m.isActive).toList();
    }

    return medications;
  }

  Future<Medication?> getMedication(String id) async {
    final response = await _supabase
        .from('medications')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Medication.fromJson(response);
  }

  Future<Medication> createMedication({
    required String petId,
    required String name,
    String? dosage,
    String? frequency,
    String? mealTiming,
    String? frequencyType,
    int? frequencyTimes,
    List<String>? timeOfDay,
    DateTime? startDate,
    DateTime? endDate,
    String? prescribedBy,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = {
      'pet_id': petId,
      'user_id': user.id,
      'name': name,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (mealTiming != null) 'meal_timing': mealTiming,
      if (frequencyType != null) 'frequency_type': frequencyType,
      if (frequencyTimes != null) 'frequency_times': frequencyTimes,
      if (timeOfDay != null && timeOfDay.isNotEmpty) 'time_of_day': timeOfDay,
      if (startDate != null)
        'start_date': startDate.toIso8601String().split('T').first,
      if (endDate != null)
        'end_date': endDate.toIso8601String().split('T').first,
      if (prescribedBy != null) 'prescribed_by': prescribedBy,
      if (notes != null) 'notes': notes,
      'is_active': true,
    };

    final response = await _supabase
        .from('medications')
        .insert(data)
        .select()
        .single();
    return Medication.fromJson(response);
  }

  Future<Medication> updateMedication(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _supabase
        .from('medications')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return Medication.fromJson(response);
  }

  Future<void> deleteMedication(String id) async {
    await _supabase.from('medications').delete().eq('id', id);
  }

  Future<void> toggleActive(String id, bool isActive) async {
    await _supabase
        .from('medications')
        .update({'is_active': isActive})
        .eq('id', id);
  }
}
