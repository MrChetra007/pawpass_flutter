import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/appointment_model.dart';
import '../../data/repositories/appointment_repository.dart';

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  return AppointmentRepository(Supabase.instance.client);
});

final appointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getAppointments();
});

final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repository = ref.watch(appointmentRepositoryProvider);
  return repository.getUpcomingAppointments();
});

final appointmentNotifierProvider = NotifierProvider<AppointmentNotifier, AsyncValue<List<Appointment>>>(() {
  return AppointmentNotifier();
});

class AppointmentNotifier extends Notifier<AsyncValue<List<Appointment>>> {
  @override
  AsyncValue<List<Appointment>> build() {
    return const AsyncValue.loading();
  }

  Future<void> loadAppointments({String? petId, String? status}) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final appointments = await repository.getAppointments(petId: petId, status: status);
      state = AsyncValue.data(appointments);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Appointment?> createAppointment({
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
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final appointment = await repository.createAppointment(
        petId: petId,
        title: title,
        datetime: datetime,
        type: type,
        vetName: vetName,
        clinicName: clinicName,
        clinicPhone: clinicPhone,
        clinicAddress: clinicAddress,
        notes: notes,
      );

      final currentAppointments = state.value ?? [];
      state = AsyncValue.data([...currentAppointments, appointment]);

      return appointment;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      final updatedAppointment = await repository.updateAppointment(id, data);

      final currentAppointments = state.value ?? [];
      state = AsyncValue.data(
        currentAppointments.map((a) => a.id == id ? updatedAppointment : a).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.deleteAppointment(id);

      final currentAppointments = state.value ?? [];
      state = AsyncValue.data(
        currentAppointments.where((a) => a.id != id).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsCompleted(String id) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.markAsCompleted(id);

      final currentAppointments = state.value ?? [];
      state = AsyncValue.data(
        currentAppointments.map((a) {
          if (a.id == id) {
            return Appointment(
              id: a.id,
              petId: a.petId,
              userId: a.userId,
              title: a.title,
              type: a.type,
              datetime: a.datetime,
              vetName: a.vetName,
              clinicName: a.clinicName,
              clinicPhone: a.clinicPhone,
              clinicAddress: a.clinicAddress,
              notes: a.notes,
              reminderSent: a.reminderSent,
              status: 'completed',
              createdAt: a.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return a;
        }).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelAppointment(String id) async {
    try {
      final repository = ref.read(appointmentRepositoryProvider);
      await repository.cancelAppointment(id);

      final currentAppointments = state.value ?? [];
      state = AsyncValue.data(
        currentAppointments.map((a) {
          if (a.id == id) {
            return Appointment(
              id: a.id,
              petId: a.petId,
              userId: a.userId,
              title: a.title,
              type: a.type,
              datetime: a.datetime,
              vetName: a.vetName,
              clinicName: a.clinicName,
              clinicPhone: a.clinicPhone,
              clinicAddress: a.clinicAddress,
              notes: a.notes,
              reminderSent: a.reminderSent,
              status: 'cancelled',
              createdAt: a.createdAt,
              updatedAt: DateTime.now(),
            );
          }
          return a;
        }).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
