import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/medication_model.dart';
import '../../data/repositories/medication_repository.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(Supabase.instance.client);
});

final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getMedications();
});

final activeMedicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getMedications(activeOnly: true);
});

final medicationNotifierProvider = NotifierProvider<MedicationNotifier, AsyncValue<List<Medication>>>(() {
  return MedicationNotifier();
});

class MedicationNotifier extends Notifier<AsyncValue<List<Medication>>> {
  @override
  AsyncValue<List<Medication>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadMedications({String? petId}) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(medicationRepositoryProvider);
      final medications = await repository.getMedications(petId: petId);
      state = AsyncValue.data(medications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Medication?> createMedication({
    required String petId,
    required String name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? prescribedBy,
    String? notes,
  }) async {
    try {
      final repository = ref.read(medicationRepositoryProvider);
      final medication = await repository.createMedication(
        petId: petId,
        name: name,
        dosage: dosage,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        prescribedBy: prescribedBy,
        notes: notes,
      );

      final currentMedications = state.value ?? [];
      state = AsyncValue.data([medication, ...currentMedications]);

      return medication;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMedication(String id, Map<String, dynamic> data) async {
    try {
      final repository = ref.read(medicationRepositoryProvider);
      final updatedMedication = await repository.updateMedication(id, data);

      final currentMedications = state.value ?? [];
      state = AsyncValue.data(
        currentMedications.map((m) => m.id == id ? updatedMedication : m).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      final repository = ref.read(medicationRepositoryProvider);
      await repository.deleteMedication(id);

      final currentMedications = state.value ?? [];
      state = AsyncValue.data(
        currentMedications.where((m) => m.id != id).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    try {
      final repository = ref.read(medicationRepositoryProvider);
      await repository.toggleActive(id, isActive);

      final currentMedications = state.value ?? [];
      state = AsyncValue.data(
        currentMedications.map((m) {
          if (m.id == id) {
            return Medication(
              id: m.id,
              petId: m.petId,
              userId: m.userId,
              name: m.name,
              dosage: m.dosage,
              frequency: m.frequency,
              startDate: m.startDate,
              endDate: m.endDate,
              prescribedBy: m.prescribedBy,
              notes: m.notes,
              isActive: isActive,
              createdAt: m.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return m;
        }).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
