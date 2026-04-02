import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/vaccine_model.dart';
import '../../data/repositories/vaccine_repository.dart';

final vaccineRepositoryProvider = Provider<VaccineRepository>((ref) {
  return VaccineRepository(Supabase.instance.client);
});

final vaccinesProvider = FutureProvider.family<List<Vaccine>, String?>((ref, petId) async {
  final repository = ref.watch(vaccineRepositoryProvider);
  return repository.getVaccines(petId: petId);
});

final vaccineNotifierProvider = NotifierProvider<VaccineNotifier, AsyncValue<List<Vaccine>>>(() {
  return VaccineNotifier();
});

class VaccineNotifier extends Notifier<AsyncValue<List<Vaccine>>> {
  @override
  AsyncValue<List<Vaccine>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadVaccines({String? petId}) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(vaccineRepositoryProvider);
      final vaccines = await repository.getVaccines(petId: petId);
      state = AsyncValue.data(vaccines);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Vaccine?> createVaccine({
    required String petId,
    required String name,
    required DateTime dateGiven,
    DateTime? nextDueDate,
    String? vetName,
    String? clinicName,
    String? batchNumber,
    String? notes,
  }) async {
    try {
      final repository = ref.read(vaccineRepositoryProvider);
      final vaccine = await repository.createVaccine(
        petId: petId,
        name: name,
        dateGiven: dateGiven,
        nextDueDate: nextDueDate,
        vetName: vetName,
        clinicName: clinicName,
        batchNumber: batchNumber,
        notes: notes,
      );

      final currentVaccines = state.value ?? [];
      state = AsyncValue.data([vaccine, ...currentVaccines]);

      return vaccine;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateVaccine(String id, Map<String, dynamic> data) async {
    try {
      final repository = ref.read(vaccineRepositoryProvider);
      final updatedVaccine = await repository.updateVaccine(id, data);

      final currentVaccines = state.value ?? [];
      state = AsyncValue.data(
        currentVaccines.map((v) => v.id == id ? updatedVaccine : v).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVaccine(String id) async {
    try {
      final repository = ref.read(vaccineRepositoryProvider);
      await repository.deleteVaccine(id);

      final currentVaccines = state.value ?? [];
      state = AsyncValue.data(
        currentVaccines.where((v) => v.id != id).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    try {
      final repository = ref.read(vaccineRepositoryProvider);
      final updatedVaccine = await repository.toggleActive(id, isActive);

      final currentVaccines = state.value ?? [];
      state = AsyncValue.data(
        currentVaccines.map((v) => v.id == id ? updatedVaccine : v).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, int> getStatusCounts() {
    final vaccines = state.value ?? [];
    return {
      'upToDate': vaccines.where((v) => v.status == VaccineStatus.upToDate).length,
      'dueSoon': vaccines.where((v) => v.status == VaccineStatus.dueSoon).length,
      'overdue': vaccines.where((v) => v.status == VaccineStatus.overdue).length,
    };
  }
}
