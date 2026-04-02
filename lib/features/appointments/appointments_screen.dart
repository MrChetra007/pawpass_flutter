import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/upgrade_modal.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: const EmptyState(
        icon: Icons.calendar_today,
        title: 'No appointments',
        subtitle: 'Schedule vet visits and grooming appointments',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => UpgradeModal.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
