import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme_data.dart';
import '../../data/models/vaccine_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/vaccine_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/status_badge.dart';
import 'add_edit_vaccine_screen.dart';

class VaccinesListScreen extends ConsumerStatefulWidget {
  final String? initialPetId;

  const VaccinesListScreen({super.key, this.initialPetId});

  @override
  ConsumerState<VaccinesListScreen> createState() => _VaccinesListScreenState();
}

class _VaccinesListScreenState extends ConsumerState<VaccinesListScreen>
    with TickerProviderStateMixin {
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.initialPetId;
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );
    Future.microtask(() {
      ref.read(vaccineNotifierProvider.notifier).loadVaccines();
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
    final vaccinesAsync = ref.watch(vaccineNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(48, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vaccines', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('Track vaccinations and reminders', style: theme.textTheme.labelLarge),
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
                  _listAnimationController.forward();
                  return _buildVaccinesList(filteredVaccines, petsAsync);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AnimatedFab(
        onPressed: () => _showAddVaccine(petsAsync),
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
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _selectedPetId = null),
                ),
              ),
              ...pets.map((pet) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(pet.name),
                      selected: _selectedPetId == pet.id,
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
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
          Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
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
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildSectionHeader(context, 'Active', activeVaccines.length),
          ),
          const SizedBox(height: 12),
          ...activeVaccines.map((vaccine) => FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildVaccineCard(vaccine, petsAsync),
                ),
              )),
          const SizedBox(height: 24),
        ],
        if (inactiveVaccines.isNotEmpty) ...[
          FadeTransition(
            opacity: _fadeAnimation,
            child: _buildSectionHeader(context, 'Inactive', inactiveVaccines.length),
          ),
          const SizedBox(height: 12),
          ...inactiveVaccines.map((vaccine) => FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildVaccineCard(vaccine, petsAsync),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
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

    return GestureDetector(
      onTap: () => _showEditVaccine(vaccine),
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
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.vaccines, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vaccine.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.pets, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        petName,
                        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ],
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StatusBadge(status: _getStatusType(vaccine.status)),
          ],
        ),
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
              child: Text(
                'Select Pet',
                style: theme.textTheme.titleLarge,
              ),
            ),
            ...pets.map((pet) => ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
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

class _AnimatedFab extends StatefulWidget {
  final VoidCallback onPressed;
  final ThemeData theme;

  const _AnimatedFab({required this.onPressed, required this.theme});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
