import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme_data.dart';
import '../../data/models/vet_record_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/record_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/paw_card.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/upgrade_modal.dart';
import 'add_edit_record_screen.dart';

class RecordsListScreen extends ConsumerStatefulWidget {
  const RecordsListScreen({super.key});

  @override
  ConsumerState<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends ConsumerState<RecordsListScreen> {
  String? _selectedPetId;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(recordNotifierProvider.notifier).loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petNotifierProvider);
    final recordsAsync = ref.watch(recordNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
      ),
      body: Column(
        children: [
          _buildPetFilter(petsAsync),
          _buildTypeFilter(),
          Expanded(
            child: recordsAsync.when(
              loading: () => _buildLoadingState(),
              error: (e, _) => _buildErrorState(e.toString()),
              data: (records) {
                final filteredRecords = _filterRecords(records);
                if (filteredRecords.isEmpty) {
                  return EmptyState(
                    icon: Icons.description,
                    title: 'No records yet',
                    subtitle: 'Add health records to keep track of your pet\'s medical history',
                    actionLabel: 'Add Record',
                    onAction: () => _showAddRecord(petsAsync),
                  );
                }
                return _buildRecordsList(filteredRecords);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecord(petsAsync),
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

  Widget _buildTypeFilter() {
    final types = ['all', 'checkup', 'surgery', 'illness', 'injury', 'dental', 'other'];
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: types.map((type) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getTypeLabel(type)),
              selected: _filterType == type,
              onSelected: (_) => setState(() => _filterType = type),
            ),
          );
        }).toList(),
      ),
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
            onPressed: () => ref.read(recordNotifierProvider.notifier).loadRecords(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(List<VetRecord> records) {
    final groupedRecords = _groupByYear(records);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final year = groupedRecords.keys.elementAt(index);
        final yearRecords = groupedRecords[year]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                year.toString(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...yearRecords.map((record) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecordCard(record),
                )),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(VetRecord record) {
    final theme = Theme.of(context);
    
    return PawCard(
      onTap: () => _showEditRecord(record),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.typeEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  record.typeLabel,
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: theme.textTheme.labelMedium?.color),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d').format(record.date),
                      style: theme.textTheme.labelMedium,
                    ),
                    if (record.clinicName != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.local_hospital, size: 14, color: theme.textTheme.labelMedium?.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          record.clinicName!,
                          style: theme.textTheme.labelMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (record.cost != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PawThemeData.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '\$${record.cost!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: PawThemeData.successGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<VetRecord> _filterRecords(List<VetRecord> records) {
    var filtered = records;
    
    if (_selectedPetId != null) {
      filtered = filtered.where((r) => r.petId == _selectedPetId).toList();
    }
    
    if (_filterType != 'all') {
      filtered = filtered.where((r) => r.type == _filterType).toList();
    }
    
    return filtered;
  }

  Map<int, List<VetRecord>> _groupByYear(List<VetRecord> records) {
    final grouped = <int, List<VetRecord>>{};
    for (final record in records) {
      final year = record.date.year;
      grouped.putIfAbsent(year, () => []).add(record);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  void _showAddRecord(AsyncValue<List> petsAsync) {
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
          builder: (context) => AddEditRecordScreen(petId: pets.first.id),
        ),
      );
    });
  }

  void _showEditRecord(VetRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRecordScreen(
          petId: record.petId,
          record: record,
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'checkup': return 'Checkup';
      case 'surgery': return 'Surgery';
      case 'illness': return 'Illness';
      case 'injury': return 'Injury';
      case 'dental': return 'Dental';
      case 'other': return 'Other';
      default: return 'All';
    }
  }
}
