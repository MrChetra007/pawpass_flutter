import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme_data.dart';
import '../../data/models/medication_model.dart';
import '../../shared/providers/medication_provider.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/paw_card.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/upgrade_modal.dart';
import 'add_edit_medication_screen.dart';

class MedicationsListScreen extends ConsumerStatefulWidget {
  final String? initialPetId;

  const MedicationsListScreen({super.key, this.initialPetId});

  @override
  ConsumerState<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends ConsumerState<MedicationsListScreen> {
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.initialPetId;
    Future.microtask(() {
      ref.read(medicationNotifierProvider.notifier).loadMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petNotifierProvider);
    final medicationsAsync = ref.watch(medicationNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
      ),
      body: Column(
        children: [
          _buildPetFilter(petsAsync),
          Expanded(
            child: medicationsAsync.when(
              loading: () => _buildLoadingState(),
              error: (e, _) => _buildErrorState(e.toString()),
              data: (medications) {
                var filteredMeds = medications;
                if (_selectedPetId != null) {
                  filteredMeds = filteredMeds.where((m) => m.petId == _selectedPetId).toList();
                }

                if (filteredMeds.isEmpty) {
                  return EmptyState(
                    icon: Icons.medication,
                    title: 'No medications',
                    subtitle: 'Track your pet\'s medications and dosages',
                    actionLabel: 'Add Medication',
                    onAction: () => _showAddMedication(petsAsync),
                  );
                }

                final activeMeds = filteredMeds.where((m) => m.isActive).toList();
                final inactiveMeds = filteredMeds.where((m) => !m.isActive).toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (activeMeds.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Active', activeMeds.length),
                      const SizedBox(height: 12),
                      ...activeMeds.map((med) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMedicationCard(med, petsAsync, true),
                          )),
                      const SizedBox(height: 24),
                    ],
                    if (inactiveMeds.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Inactive', inactiveMeds.length),
                      const SizedBox(height: 12),
                      ...inactiveMeds.map((med) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMedicationCard(med, petsAsync, false),
                          )),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedication(petsAsync),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildPetFilter(AsyncValue<List> petsAsync) {
    return petsAsync.when(
      data: (pets) {
        if (pets.isEmpty) return const SizedBox();
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All Pets'),
                  selected: _selectedPetId == null,
                  onSelected: (_) => setState(() => _selectedPetId = null),
                ),
              ),
              ...pets.map((pet) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(pet.name),
                      selected: _selectedPetId == pet.id,
                      onSelected: (_) => setState(() => _selectedPetId = pet.id),
                    ),
                  )),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonCard(),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(medicationNotifierProvider.notifier).loadMedications(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication, AsyncValue<List> petsAsync, bool isActive) {
    final theme = Theme.of(context);
    final color = isActive ? PawThemeData.successGreen : Colors.grey;

    String petName = 'Unknown Pet';
    petsAsync.whenData((pets) {
      final pet = pets.where((p) => p.id == medication.petId).firstOrNull;
      if (pet != null) petName = pet.name;
    });

    return PawCard(
      onTap: () => _showEditMedication(medication),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medication,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  petName,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (medication.dosage != null) ...[
                      Icon(Icons.science, size: 14, color: theme.textTheme.labelMedium?.color),
                      const SizedBox(width: 4),
                      Text(
                        medication.dosage!,
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (medication.frequency != null) ...[
                      Icon(Icons.schedule, size: 14, color: theme.textTheme.labelMedium?.color),
                      const SizedBox(width: 4),
                      Text(
                        medication.frequencyLabel,
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ],
                ),
                if (medication.endDate != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event, size: 14, color: theme.textTheme.labelMedium?.color),
                      const SizedBox(width: 4),
                      Text(
                        'Until ${DateFormat('MMM d').format(medication.endDate!)}',
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isActive)
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'toggle',
                  child: Text('Mark as Inactive'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
              onSelected: (value) {
                if (value == 'toggle') {
                  ref
                      .read(medicationNotifierProvider.notifier)
                      .toggleActive(medication.id, false);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(medication);
                }
              },
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication?'),
        content: Text('Are you sure you want to delete ${medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(medicationNotifierProvider.notifier).deleteMedication(medication.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddMedication(AsyncValue<List> petsAsync) {
    petsAsync.whenData((pets) {
      if (pets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a pet first')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEditMedicationScreen(petId: pets.first.id),
        ),
      );
    });
  }

  void _showEditMedication(Medication medication) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMedicationScreen(
          petId: medication.petId,
          medication: medication,
        ),
      ),
    );
  }
}
