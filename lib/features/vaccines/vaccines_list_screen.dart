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
  const VaccinesListScreen({super.key});

  @override
  ConsumerState<VaccinesListScreen> createState() => _VaccinesListScreenState();
}

class _VaccinesListScreenState extends ConsumerState<VaccinesListScreen> {
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
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
                return _buildVaccinesList(filteredVaccines);
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

  Widget _buildVaccinesList(List<Vaccine> vaccines) {
    final groupedVaccines = _groupByStatus(vaccines);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusSummary(vaccines),
        const SizedBox(height: 24),
        if (groupedVaccines['overdue']!.isNotEmpty) ...[
          _buildSection('OVERDUE', groupedVaccines['overdue']!, Colors.red),
          const SizedBox(height: 16),
        ],
        if (groupedVaccines['dueSoon']!.isNotEmpty) ...[
          _buildSection('DUE SOON', groupedVaccines['dueSoon']!, Colors.orange),
          const SizedBox(height: 16),
        ],
        if (groupedVaccines['upToDate']!.isNotEmpty) ...[
          _buildSection('UP TO DATE', groupedVaccines['upToDate']!, PawThemeData.successGreen),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildStatusSummary(List<Vaccine> vaccines) {
    final counts = {
      'Up to date': vaccines.where((v) => v.status == VaccineStatus.upToDate).length,
      'Due soon': vaccines.where((v) => v.status == VaccineStatus.dueSoon).length,
      'Overdue': vaccines.where((v) => v.status == VaccineStatus.overdue).length,
    };

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: counts.entries.map((entry) {
          Color color;
          IconData icon;
          switch (entry.key) {
            case 'Overdue':
              color = Colors.red;
              icon = Icons.error;
              break;
            case 'Due soon':
              color = Colors.orange;
              icon = Icons.schedule;
              break;
            default:
              color = PawThemeData.successGreen;
              icon = Icons.check_circle;
          }
          return Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                '${entry.value}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                entry.key,
                style: theme.textTheme.labelMedium,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection(String title, List<Vaccine> vaccines, Color color) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...vaccines.map((vaccine) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildVaccineCard(vaccine, color),
            )),
      ],
    );
  }

  Widget _buildVaccineCard(Vaccine vaccine, Color statusColor) {
    final theme = Theme.of(context);

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
        ],
      ),
    );
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

  Map<String, List<Vaccine>> _groupByStatus(List<Vaccine> vaccines) {
    return {
      'overdue': vaccines.where((v) => v.status == VaccineStatus.overdue).toList(),
      'dueSoon': vaccines.where((v) => v.status == VaccineStatus.dueSoon).toList(),
      'upToDate': vaccines.where((v) => v.status == VaccineStatus.upToDate).toList(),
      'unknown': vaccines.where((v) => v.status == VaccineStatus.unknown).toList(),
    };
  }

  void _showAddVaccine(AsyncValue<List> petsAsync) {
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
          builder: (context) => AddEditVaccineScreen(petId: pets.first.id),
        ),
      );
    });
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
