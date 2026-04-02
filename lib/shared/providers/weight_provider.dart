import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/weight_log_model.dart';
import '../../data/repositories/weight_repository.dart';

final weightRepositoryProvider = Provider<WeightRepository>((ref) {
  return WeightRepository(Supabase.instance.client);
});

final weightLogsProvider = FutureProvider.family<List<WeightLog>, String>((ref, petId) async {
  final repository = ref.watch(weightRepositoryProvider);
  return repository.getWeightLogs(petId: petId);
});

final weightNotifierProvider = NotifierProvider<WeightNotifier, AsyncValue<List<WeightLog>>>(() {
  return WeightNotifier();
});

class WeightNotifier extends Notifier<AsyncValue<List<WeightLog>>> {
  @override
  AsyncValue<List<WeightLog>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadWeightLogs({String? petId}) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(weightRepositoryProvider);
      final logs = await repository.getWeightLogs(petId: petId);
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<WeightLog?> createWeightLog({
    required String petId,
    required double weightKg,
    required DateTime recordedAt,
    String? notes,
  }) async {
    try {
      final repository = ref.read(weightRepositoryProvider);
      final log = await repository.createWeightLog(
        petId: petId,
        weightKg: weightKg,
        recordedAt: recordedAt,
        notes: notes,
      );

      final currentLogs = state.value ?? [];
      state = AsyncValue.data([log, ...currentLogs]);

      return log;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteWeightLog(String id) async {
    try {
      final repository = ref.read(weightRepositoryProvider);
      await repository.deleteWeightLog(id);

      final currentLogs = state.value ?? [];
      state = AsyncValue.data(
        currentLogs.where((l) => l.id != id).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
