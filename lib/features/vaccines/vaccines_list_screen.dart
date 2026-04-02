import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme_data.dart';
import '../../data/models/vaccine_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/vaccine_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/paw_card.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/status_badge.dart';
import 'add_edit_vaccine_screen.dart';

class VaccinesListScreen extends ConsumerStatefulWidget {
  final String? initialPetId;

  const VaccinesListScreen({super.key, this.initialPetId});

  @override
  ConsumerState<VaccinesListScreen> createState() => _VaccinesListScreenState();
}

class _VaccinesListScreenState extends ConsumerState<VaccinesListScreen> {
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.initialPetId;
    Future.microtask(() {
      ref.read(vaccineNotifierProvider.notifier).loadVaccines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petNotifierProvider);
    final vaccinesAsync = ref.watch(vaccineNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vaccines'),
      ),
      body: Column(
        children: [
          _buildPetFilter(petsAsync),
          Expanded(
            child: vaccinesAsync.when(
              loading: () => _buildLoadingState(),
              error: (e, _) => _buildErrorState(e.toString()),
              data: (vaccines) {
                final filteredVaccines = _selectedPetId != null
                    ? vaccines.where((v) => v.petId == _selectedPetId).toList()
                    : vaccines;

                if (filteredVaccines.isEmpty) {
                  return EmptyState(
                    icon: Icons.vaccines,
                    title: 'No vaccines yet',
                    subtitle: 'Track your pet\'s vaccinations and get reminders',
                    actionLabel: 'Add Vaccine',
                    onAction: () => _showAddVaccine(petsAsync),
                  );
                }
                return _buildVaccinesList(filteredVaccines, petsAsync);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddVaccine(petsAsync),
        child: const Icon(Icons.add),
      ),
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
            onPressed: () => ref.read(vaccineNotifierProvider.notifier).loadVaccines(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinesList(List<Vaccine> vaccines, AsyncValue<List> petsAsync) {
    final activeVaccines = vaccines.where((v) => v.isActive).toList();
    final inactiveVaccines = vaccines.where((v) => !v.isActive).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeVaccines.isNotEmpty) ...[
          _buildSectionHeader(context, 'Active', activeVaccines.length),
          const SizedBox(height: 12),
          ...activeVaccines.map((vaccine) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildVaccineCard(vaccine, petsAsync),
              )),
          const SizedBox(height: 24),
        ],
        if (inactiveVaccines.isNotEmpty) ...[
          _buildSectionHeader(context, 'Inactive', inactiveVaccines.length),
          const SizedBox(height: 12),
          ...inactiveVaccines.map((vaccine) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildVaccineCard(vaccine, petsAsync),
              )),
        ],
      ],
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

  Widget _buildVaccineCard(Vaccine vaccine, AsyncValue<List> petsAsync) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(vaccine.status);

    String petName = 'Unknown Pet';
    petsAsync.whenData((pets) {
      final pet = pets.where((p) => p.id == vaccine.petId).firstOrNull;
      if (pet != null) petName = pet.name;
    });

    return PawCard(
      onTap: () => _showEditVaccine(vaccine),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.vaccines, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccine.name,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  petName,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Given: ${DateFormat('MMM d, yyyy').format(vaccine.dateGiven)}',
                  style: theme.textTheme.labelMedium,
                ),
                if (vaccine.nextDueDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Due: ${DateFormat('MMM d, yyyy').format(vaccine.nextDueDate!)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          StatusBadge(status: _getStatusType(vaccine.status)),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(vaccine.isActive ? 'Mark as Inactive' : 'Mark as Active'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) {
              if (value == 'toggle') {
                ref
                    .read(vaccineNotifierProvider.notifier)
                    .toggleActive(vaccine.id, !vaccine.isActive);
              } else if (value == 'delete') {
                _showDeleteConfirmation(vaccine);
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(VaccineStatus status) {
    switch (status) {
      case VaccineStatus.upToDate:
        return PawThemeData.successGreen;
      case VaccineStatus.dueSoon:
        return Colors.orange;
      case VaccineStatus.overdue:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  StatusType _getStatusType(VaccineStatus status) {
    switch (status) {
      case VaccineStatus.upToDate:
        return StatusType.upToDate;
      case VaccineStatus.dueSoon:
        return StatusType.dueSoon;
      case VaccineStatus.overdue:
        return StatusType.overdue;
      default:
        return StatusType.unknown;
    }
  }

  void _showDeleteConfirmation(Vaccine vaccine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vaccine?'),
        content: Text('Are you sure you want to delete ${vaccine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(vaccineNotifierProvider.notifier).deleteVaccine(vaccine.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddVaccine(AsyncValue<List> petsAsync) {
    petsAsync.whenData((pets) {
      if (pets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add a pet first')),
        );
        return;
      }

      if (_selectedPetId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditVaccineScreen(petId: _selectedPetId!),
          ),
        );
      } else {
        _showPetPicker(pets);
      }
    });
  }

  void _showPetPicker(List pets) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Pet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...pets.map((pet) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                child: Text(pet.speciesEmoji),
              ),
              title: Text(pet.name),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditVaccineScreen(petId: pet.id),
                  ),
                );
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditVaccine(Vaccine vaccine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditVaccineScreen(
          petId: vaccine.petId,
          vaccine: vaccine,
        ),
      ),
    );
  }
}
