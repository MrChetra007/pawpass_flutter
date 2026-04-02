import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment_model.dart';

class AppointmentRepository {
  final SupabaseClient _supabase;

  AppointmentRepository(this._supabase);

  Future<List<Appointment>> getAppointments({String? petId, String? status}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('appointments')
        .select()
        .eq('user_id', user.id)
        .order('datetime', ascending: true);

    final appointments = (response as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();

    var filtered = appointments;
    
    if (petId != null) {
      filtered = filtered.where((a) => a.petId == petId).toList();
    }
    
    if (status != null) {
      filtered = filtered.where((a) => a.status == status).toList();
    }

    return filtered;
  }

  Future<List<Appointment>> getUpcomingAppointments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _supabase
        .from('appointments')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'upcoming')
        .gte('datetime', now)
        .order('datetime', ascending: true)
        .limit(5);

    return (response as List)
        .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Appointment?> getAppointment(String id) async {
    final response = await _supabase
        .from('appointments')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Appointment.fromJson(response as Map<String, dynamic>);
  }

  Future<Appointment> createAppointment({
    required String petId,
    required String title,
    required DateTime datetime,
    String? type,
    String? vetName,
    String? clinicName,
    String? clinicPhone,
    String? clinicAddress,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = {
      'pet_id': petId,
      'user_id': user.id,
      'title': title,
      'datetime': datetime.toUtc().toIso8601String(),
      if (type != null) 'type': type,
      if (vetName != null) 'vet_name': vetName,
      if (clinicName != null) 'clinic_name': clinicName,
      if (clinicPhone != null) 'clinic_phone': clinicPhone,
      if (clinicAddress != null) 'clinic_address': clinicAddress,
      if (notes != null) 'notes': notes,
      'status': 'upcoming',
    };

    final response = await _supabase.from('appointments').insert(data).select().single();
    return Appointment.fromJson(response as Map<String, dynamic>);
  }

  Future<Appointment> updateAppointment(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('appointments')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return Appointment.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAppointment(String id) async {
    await _supabase.from('appointments').delete().eq('id', id);
  }

  Future<void> markAsCompleted(String id) async {
    await _supabase
        .from('appointments')
        .update({'status': 'completed'})
        .eq('id', id);
  }

  Future<void> cancelAppointment(String id) async {
    await _supabase
        .from('appointments')
        .update({'status': 'cancelled'})
        .eq('id', id);
  }
}
