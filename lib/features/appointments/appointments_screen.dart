import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme_data.dart';
import '../../core/utils/feature_gate.dart';
import '../../data/models/appointment_model.dart';
import '../../shared/providers/appointment_provider.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/skeleton_loader.dart';
import 'add_edit_appointment_screen.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  String? _selectedPetId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimationController, curve: Curves.easeOut),
    );
    Future.microtask(() {
      ref.read(appointmentNotifierProvider.notifier).loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petNotifierProvider);
    final appointmentsAsync = ref.watch(appointmentNotifierProvider);
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
                      Text('Appointments', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('Schedule and manage your visits', style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.textTheme.labelLarge?.color,
                  indicatorColor: theme.colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            _buildPetFilter(petsAsync),
            Expanded(
              child: appointmentsAsync.when(
                loading: () => _buildLoadingState(),
                error: (e, _) => _buildErrorState(e.toString()),
                data: (appointments) {
                  final filteredAppointments = _selectedPetId != null
                      ? appointments.where((a) => a.petId == _selectedPetId).toList()
                      : appointments;

                  if (filteredAppointments.isEmpty) {
                    return EmptyState(
                      icon: Icons.calendar_today,
                      title: 'No appointments',
                      subtitle: 'Schedule vet visits and grooming appointments',
                      actionLabel: 'Add Appointment',
                      onAction: () => _checkAndAddAppointment(petsAsync),
                    );
                  }

                  _listAnimationController.forward();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentsList(
                        filteredAppointments
                            .where((a) => a.status == 'upcoming')
                            .toList(),
                        'upcoming',
                        petsAsync,
                      ),
                      _buildAppointmentsList(
                        filteredAppointments
                            .where((a) => a.status != 'upcoming')
                            .toList(),
                        'past',
                        petsAsync,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _AnimatedFab(
        onPressed: () => _checkAndAddAppointment(petsAsync),
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
            onPressed: () =>
                ref.read(appointmentNotifierProvider.notifier).loadAppointments(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<Appointment> appointments,
    String type,
    AsyncValue<List> petsAsync,
  ) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'upcoming' ? 'No upcoming appointments' : 'No past appointments',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAppointmentCard(appointments[index], petsAsync),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment, AsyncValue<List> petsAsync) {
    final theme = Theme.of(context);
    final isPast = appointment.status != 'upcoming';

    Color borderColor;
    switch (appointment.status) {
      case 'completed':
        borderColor = PawThemeData.successGreen;
        break;
      case 'cancelled':
        borderColor = Colors.grey;
        break;
      default:
        borderColor = appointment.datetime.isBefore(DateTime.now())
            ? Colors.red
            : theme.colorScheme.primary;
    }

    String petName = 'Unknown Pet';
    petsAsync.whenData((pets) {
      final pet = pets.where((p) => p.id == appointment.petId).firstOrNull;
      if (pet != null) petName = pet.name;
    });

    return Dismissible(
      key: Key(appointment.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: PawThemeData.successGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.cancel, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await ref
              .read(appointmentNotifierProvider.notifier)
              .markAsCompleted(appointment.id);
          return false;
        } else {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel Appointment'),
              content: const Text('Are you sure you want to cancel this appointment?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref
                .read(appointmentNotifierProvider.notifier)
                .cancelAppointment(appointment.id);
          }
          return false;
        }
      },
      child: GestureDetector(
        onTap: () => _showEditAppointment(appointment),
        child: Container(
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
            border: Border(
              left: BorderSide(color: borderColor, width: 4),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Icon(
                  _getTypeIcon(appointment.type),
                  color: borderColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appointment.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: isPast ? TextDecoration.lineThrough : null,
                                color: isPast ? theme.textTheme.labelLarge?.color : null,
                              ),
                            ),
                          ),
                          if (appointment.status == 'cancelled')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Cancelled',
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.pets,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            petName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.textTheme.labelMedium?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(appointment.datetime),
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.textTheme.labelMedium?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('h:mm a').format(appointment.datetime),
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                      if (appointment.clinicName != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: theme.textTheme.labelMedium?.color,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                appointment.clinicName!,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'vet':
        return Icons.medical_services;
      case 'grooming':
        return Icons.content_cut;
      case 'training':
        return Icons.school;
      default:
        return Icons.event;
    }
  }

  void _checkAndAddAppointment(AsyncValue<List> petsAsync) async {
    final canAccess = await FeatureGate.check(
      context: context,
      ref: ref,
      feature: 'appointments',
      customMessage: 'Create and manage appointments with Paw Plan',
    );

    if (canAccess && mounted) {
      _showAddAppointment(petsAsync);
    }
  }

  void _showAddAppointment(AsyncValue<List> petsAsync) {
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
            builder: (context) => AddEditAppointmentScreen(petId: _selectedPetId!),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...pets.map((pet) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(pet.speciesEmoji),
              ),
              title: Text(pet.name),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditAppointmentScreen(petId: pet.id),
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

  void _showEditAppointment(Appointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditAppointmentScreen(
          petId: appointment.petId,
          appointment: appointment,
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