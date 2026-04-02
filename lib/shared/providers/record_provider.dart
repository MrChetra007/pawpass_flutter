import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/vet_record_model.dart';
import '../../data/repositories/record_repository.dart';

export '../../data/repositories/record_repository.dart';

final recordRepositoryProvider = Provider<RecordRepository>((ref) {
  return RecordRepository(Supabase.instance.client);
});

final recordsProvider = FutureProvider.family<List<VetRecord>, String?>((ref, petId) async {
  final repository = ref.watch(recordRepositoryProvider);
  return repository.getRecords(petId: petId);
});

final recordNotifierProvider = NotifierProvider<RecordNotifier, AsyncValue<List<VetRecord>>>(() {
  return RecordNotifier();
});

class RecordNotifier extends Notifier<AsyncValue<List<VetRecord>>> {
  @override
  AsyncValue<List<VetRecord>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadRecords({String? petId}) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(recordRepositoryProvider);
      final records = await repository.getRecords(petId: petId);
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<VetRecord?> createRecord({
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
    try {
      final repository = ref.read(recordRepositoryProvider);
      final record = await repository.createRecord(
        petId: petId,
        type: type,
        title: title,
        date: date,
        vetName: vetName,
        clinicName: clinicName,
        diagnosis: diagnosis,
        treatment: treatment,
        notes: notes,
        docUrl: docUrl,
        cost: cost,
      );
      
      final currentRecords = state.value ?? [];
      state = AsyncValue.data([record, ...currentRecords]);
      
      return record;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRecord(String id, Map<String, dynamic> data) async {
    try {
      final repository = ref.read(recordRepositoryProvider);
      final updatedRecord = await repository.updateRecord(id, data);
      
      final currentRecords = state.value ?? [];
      state = AsyncValue.data(
        currentRecords.map((r) => r.id == id ? updatedRecord : r).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final repository = ref.read(recordRepositoryProvider);
      await repository.deleteRecord(id);
      
      final currentRecords = state.value ?? [];
      state = AsyncValue.data(
        currentRecords.where((r) => r.id != id).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
