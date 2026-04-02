import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vaccine_model.dart';

class VaccineRepository {
  final SupabaseClient _supabase;

  VaccineRepository(this._supabase);

  Future<List<Vaccine>> getVaccines({String? petId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('vaccines')
        .select()
        .eq('user_id', user.id)
        .order('next_due_date', ascending: true, nullsFirst: false);

    final vaccines = (response as List)
        .map((json) => Vaccine.fromJson(json as Map<String, dynamic>))
        .toList();

    if (petId != null) {
      return vaccines.where((v) => v.petId == petId).toList();
    }

    return vaccines;
  }

  Future<Vaccine?> getVaccine(String id) async {
    final response = await _supabase
        .from('vaccines')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Vaccine.fromJson(response as Map<String, dynamic>);
  }

  Future<Vaccine> createVaccine({
    required String petId,
    required String name,
    required DateTime dateGiven,
    DateTime? nextDueDate,
    String? vetName,
    String? clinicName,
    String? batchNumber,
    String? docUrl,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = {
      'pet_id': petId,
      'user_id': user.id,
      'name': name,
      'date_given': dateGiven.toIso8601String().split('T').first,
      if (nextDueDate != null) 'next_due_date': nextDueDate.toIso8601String().split('T').first,
      if (vetName != null) 'vet_name': vetName,
      if (clinicName != null) 'clinic_name': clinicName,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (docUrl != null) 'doc_url': docUrl,
      if (notes != null) 'notes': notes,
    };

    final response = await _supabase.from('vaccines').insert(data).select().single();
    return Vaccine.fromJson(response as Map<String, dynamic>);
  }

  Future<Vaccine> updateVaccine(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('vaccines')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return Vaccine.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteVaccine(String id) async {
    await _supabase.from('vaccines').delete().eq('id', id);
  }

  Future<Vaccine> toggleActive(String id, bool isActive) async {
    final response = await _supabase
        .from('vaccines')
        .update({'is_active': isActive})
        .eq('id', id)
        .select()
        .single();

    return Vaccine.fromJson(response as Map<String, dynamic>);
  }
}
