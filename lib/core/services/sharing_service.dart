import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/pet_model.dart';

class SharingService {
  static final SharingService _instance = SharingService._internal();
  factory SharingService() => _instance;
  SharingService._internal();

  final _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  static const String shareBaseUrl = 'https://pawpass.vercel.app/pet';

  Future<void> enableSharing(String petId) async {
    await _supabase.from('pets').update({
      'is_sharing_enabled': true,
      'share_token': _uuid.v4(),
    }).eq('id', petId);
  }

  Future<void> disableSharing(String petId) async {
    await _supabase.from('pets').update({
      'is_sharing_enabled': false,
    }).eq('id', petId);
  }

  Future<String> regenerateToken(String petId) async {
    final newToken = _uuid.v4();
    await _supabase.from('pets').update({
      'share_token': newToken,
    }).eq('id', petId);
    return newToken;
  }

  String getShareUrl(String? token) {
    if (token == null || token.isEmpty) return '';
    return '$shareBaseUrl?token=$token';
  }

  Future<bool> isSharingEnabled(String petId) async {
    final response = await _supabase
        .from('pets')
        .select('is_sharing_enabled')
        .eq('id', petId)
        .maybeSingle();
    return response?['is_sharing_enabled'] as bool? ?? false;
  }

  Future<Pet?> getSharedPet(String token) async {
    final response = await _supabase
        .from('pets')
        .select()
        .eq('share_token', token)
        .eq('is_sharing_enabled', true)
        .maybeSingle();
    if (response == null) return null;
    return Pet.fromJson(response);
  }
}