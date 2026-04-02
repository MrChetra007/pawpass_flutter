import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/pet_model.dart';
import '../../data/repositories/pet_repository.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(Supabase.instance.client);
});

final petsProvider = FutureProvider<List<Pet>>((ref) async {
  final repository = ref.watch(petRepositoryProvider);
  return repository.getPets();
});

final selectedPetIdProvider = StateProvider<String?>((ref) => null);

final selectedPetProvider = FutureProvider<Pet?>((ref) async {
  final petId = ref.watch(selectedPetIdProvider);
  if (petId == null) {
    final pets = await ref.watch(petsProvider.future);
    return pets.isNotEmpty ? pets.first : null;
  }
  final repository = ref.watch(petRepositoryProvider);
  return repository.getPet(petId);
});

final petNotifierProvider =
    NotifierProvider<PetNotifier, AsyncValue<List<Pet>>>(() {
      return PetNotifier();
    });

class PetNotifier extends Notifier<AsyncValue<List<Pet>>> {
  @override
  AsyncValue<List<Pet>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadPets() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(petRepositoryProvider);
      final pets = await repository.getPets();
      state = AsyncValue.data(pets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Pet?> createPet({
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
    try {
      final repository = ref.read(petRepositoryProvider);
      final pet = await repository.createPet(
        name: name,
        species: species,
        breed: breed,
        gender: gender,
        dob: dob,
        weightKg: weightKg,
        color: color,
        microchip: microchip,
        neutered: neutered,
        photoUrl: photoUrl,
        notes: notes,
      );

      final currentPets = state.value ?? [];
      state = AsyncValue.data([pet, ...currentPets]);

      return pet;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePet(String id, Map<String, dynamic> data) async {
    try {
      final repository = ref.read(petRepositoryProvider);
      final updatedPet = await repository.updatePet(id, data);

      final currentPets = state.value ?? [];
      state = AsyncValue.data(
        currentPets.map((p) => p.id == id ? updatedPet : p).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePet(String id) async {
    try {
      final repository = ref.read(petRepositoryProvider);
      await repository.deletePet(id);

      final currentPets = state.value ?? [];
      state = AsyncValue.data(currentPets.where((p) => p.id != id).toList());
    } catch (e) {
      rethrow;
    }
  }
}
