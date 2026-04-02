import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/weight_log_model.dart';

class WeightRepository {
  final SupabaseClient _supabase;

  WeightRepository(this._supabase);

  Future<List<WeightLog>> getWeightLogs({String? petId}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('weight_logs')
        .select()
        .eq('user_id', user.id)
        .order('recorded_at', ascending: false);

    var logs = (response as List)
        .map((json) => WeightLog.fromJson(json as Map<String, dynamic>))
        .toList();

    if (petId != null) {
      logs = logs.where((l) => l.petId == petId).toList();
    }

    return logs;
  }

  Future<WeightLog?> getLatestWeight({required String petId}) async {
    final response = await _supabase
        .from('weight_logs')
        .select()
        .eq('pet_id', petId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return WeightLog.fromJson(response as Map<String, dynamic>);
  }

  Future<WeightLog> createWeightLog({
    required String petId,
    required double weightKg,
    required DateTime recordedAt,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = {
      'pet_id': petId,
      'user_id': user.id,
      'weight_kg': weightKg,
      'recorded_at': recordedAt.toIso8601String().split('T').first,
      if (notes != null) 'notes': notes,
    };

    final response = await _supabase.from('weight_logs').insert(data).select().single();
    return WeightLog.fromJson(response as Map<String, dynamic>);
  }

  Future<WeightLog> updateWeightLog(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('weight_logs')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return WeightLog.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteWeightLog(String id) async {
    await _supabase.from('weight_logs').delete().eq('id', id);
  }
}
