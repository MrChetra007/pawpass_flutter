import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet_model.dart';

class PetRepository {
  final SupabaseClient _supabase;

  PetRepository(this._supabase);

  Future<List<Pet>> getPets() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final response = await _supabase
        .from('pets')
        .select()
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Pet.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Pet?> getPet(String id) async {
    final response = await _supabase
        .from('pets')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Pet.fromJson(response as Map<String, dynamic>);
  }

  Future<Pet> createPet({
    required String name,
    required String species,
    String? breed,
    String? gender,
    DateTime? dob,
    double? weightKg,
    String? color,
    String? microchip,
    bool neutered = false,
    String? photoUrl,
    String? notes,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final data = {
      'user_id': user.id,
      'name': name,
      'species': species,
      if (breed != null) 'breed': breed,
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': dob.toIso8601String().split('T').first,
      if (weightKg != null) 'weight_kg': weightKg,
      if (color != null) 'color': color,
      if (microchip != null) 'microchip': microchip,
      'neutered': neutered,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (notes != null) 'notes': notes,
    };

    final response = await _supabase
        .from('pets')
        .insert(data)
        .select()
        .single();
    return Pet.fromJson(response as Map<String, dynamic>);
  }

  Future<Pet> updatePet(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('pets')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return Pet.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deletePet(String id) async {
    await _supabase.from('pets').update({'is_active': false}).eq('id', id);
  }
}
