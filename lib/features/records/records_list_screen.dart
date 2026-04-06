import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme_data.dart';
import '../../data/models/vet_record_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/record_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/upgrade_modal.dart';
import 'add_edit_record_screen.dart';

class RecordsListScreen extends ConsumerStatefulWidget {
  const RecordsListScreen({super.key});

  @override
  ConsumerState<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends ConsumerState<RecordsListScreen>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  String? _selectedPetId;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );
    Future.microtask(() {
      ref.read(recordNotifierProvider.notifier).loadRecords();
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petNotifierProvider);
    final recordsAsync = ref.watch(recordNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Records',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your pet\'s medical history',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
                      subtitle:
                          'Add health records to keep track of your pet\'s medical history',
                      actionLabel: 'Add Record',
                      onAction: () => _showAddRecord(petsAsync),
                    );
                  }
                  _listAnimationController.forward();
                  return _buildRecordsList(filteredRecords);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AnimatedFab(
        onPressed: () => _showAddRecord(petsAsync),
        theme: theme,
      ),
    );
  }

  Widget _buildPetFilter(AsyncValue<List> petsAsync) {
    final theme = Theme.of(context);
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
                  selectedColor: theme.colorScheme.primary.withValues(
                    alpha: 0.2,
                  ),
                  onSelected: (_) => setState(() => _selectedPetId = null),
                ),
              ),
              ...pets.map(
                (pet) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(pet.name),
                    selected: _selectedPetId == pet.id,
                    selectedColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                    onSelected: (_) => setState(() => _selectedPetId = pet.id),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildTypeFilter() {
    final theme = Theme.of(context);
    final types = [
      'all',
      'checkup',
      'surgery',
      'illness',
      'injury',
      'dental',
      'other',
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: types.map((type) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getTypeLabel(type)),
              selected: _filterType == type,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.colorScheme.primary,
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(recordNotifierProvider.notifier).loadRecords(),
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
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        year.toString(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${yearRecords.length} record${yearRecords.length > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
            ...yearRecords.asMap().entries.map((entry) {
              final recordIndex = entry.key;
              final record = entry.value;
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRecordCard(record),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(VetRecord record) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showEditRecord(record),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                record.typeEmoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record.typeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: theme.textTheme.labelMedium?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(record.date),
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  if (record.clinicName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital,
                          size: 14,
                          color: theme.textTheme.labelMedium?.color,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            record.clinicName!,
                            style: theme.textTheme.labelMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (record.docUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _viewDocument(record.docUrl!),
                      child: Text(
                        'View Document',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: PawThemeData.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '\$${record.cost!.toStringAsFixed(2)}',
                style: TextStyle(
                  color: PawThemeData.successGreen,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
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
    return grouped;
  }

  Future<void> _viewDocument(String url) async {
    try {
      final uri = Uri.parse(url);
      
      if (Platform.isAndroid) {
        final browserUri = Uri.parse('https://google.com/chrome');
        if (await canLaunchUrl(browserUri) != true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please install a browser to view documents')),
            );
          }
          return;
        }
      }

      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No app found to open this document')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  void _showAddRecord(AsyncValue<List> petsAsync) {
    petsAsync.whenData((pets) {
      if (pets.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Add a pet first')));
        return;
      }

      if (_selectedPetId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditRecordScreen(petId: _selectedPetId!),
          ),
        );
      } else {
        _showPetPicker(pets);
      }
    });
  }

  void _showPetPicker(List pets) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Select Pet', style: theme.textTheme.titleLarge),
            ),
            ...pets.map(
              (pet) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(pet.speciesEmoji),
                ),
                title: Text(pet.name),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditRecordScreen(petId: pet.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditRecord(VetRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddEditRecordScreen(petId: record.petId, record: record),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'checkup':
        return 'Checkup';
      case 'surgery':
        return 'Surgery';
      case 'illness':
        return 'Illness';
      case 'injury':
        return 'Injury';
      case 'dental':
        return 'Dental';
      case 'other':
        return 'Other';
      default:
        return 'All';
    }
  }
}

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  final ThemeData theme;

  const _AnimatedFab({required this.onPressed, required this.theme});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: () {
          _controller.forward().then((_) {
            _controller.reverse();
            widget.onPressed();
          });
        },
        backgroundColor: widget.theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
