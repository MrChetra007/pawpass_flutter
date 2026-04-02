import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vet_record_model.dart';

class RecordRepository {
  final SupabaseClient _supabase;

  RecordRepository(this._supabase);

  Future<List<VetRecord>> getRecords({String? petId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('vet_records')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false);

    final records = (response as List)
        .map((json) => VetRecord.fromJson(json as Map<String, dynamic>))
        .toList();
    
    if (petId != null) {
      return records.where((r) => r.petId == petId).toList();
    }
    
    return records;
  }

  Future<VetRecord?> getRecord(String id) async {
    final response = await _supabase
        .from('vet_records')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return VetRecord.fromJson(response as Map<String, dynamic>);
  }

  Future<VetRecord> createRecord({
    required String petId,
    required String type,
    required String title,
    required DateTime date,
    String? vetName,
    String? clinicName,
    String? diagnosis,
    String? treatment,
    String? notes,
    String? docUrl,
    double? cost,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = {
      'pet_id': petId,
      'user_id': user.id,
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

    final response = await _supabase.from('vet_records').insert(data).select().single();
    return VetRecord.fromJson(response as Map<String, dynamic>);
  }

  Future<VetRecord> updateRecord(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('vet_records')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return VetRecord.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteRecord(String id) async {
    await _supabase.from('vet_records').delete().eq('id', id);
  }
}
