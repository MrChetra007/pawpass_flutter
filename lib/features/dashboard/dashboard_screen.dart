import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme_data.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/feature_gate.dart';
import '../../data/models/vaccine_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/vaccine_provider.dart';
import '../../shared/providers/appointment_provider.dart';
import '../../shared/providers/medication_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../features/vaccines/vaccines_list_screen.dart';
import '../../features/medications/medications_list_screen.dart';
import '../../features/appointments/appointments_screen.dart';
import '../../features/pets/add_edit_pet_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _initAnimations() {
    _controllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );
    _fadeAnimations = _controllers
        .map(
          (controller) => Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
        )
        .toList();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        for (var i = 0; i < _controllers.length; i++) {
          Future.delayed(Duration(milliseconds: i * 100), () {
            if (mounted) _controllers[i].forward();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(petNotifierProvider.notifier).loadPets();
      ref.read(vaccineNotifierProvider.notifier).loadVaccines();
      ref.read(appointmentNotifierProvider.notifier).loadAppointments();
      ref.read(medicationNotifierProvider.notifier).loadMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(petNotifierProvider);
          ref.invalidate(vaccineNotifierProvider);
          ref.invalidate(appointmentNotifierProvider);
          ref.invalidate(medicationNotifierProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final userAsync = ref.watch(userProvider);
                            return Row(
                              children: [
                                userAsync.when(
                                  data: (user) => CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                    backgroundImage: user?.avatarUrl != null
                                        ? NetworkImage(user!.avatarUrl!)
                                        : null,
                                    child: user?.avatarUrl == null
                                        ? Icon(
                                            Icons.person,
                                            color: theme.colorScheme.primary,
                                          )
                                        : null,
                                  ),
                                  loading: () => CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  ),
                                  error: (_, __) => CircleAvatar(
                                    radius: 24,
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      userAsync.when(
                                        data: (user) => Text(
                                          user?.fullName ?? 'Pet Lover',
                                          style: theme.textTheme.headlineMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        loading: () => Text(
                                          'Loading...',
                                          style: theme.textTheme.headlineMedium,
                                        ),
                                        error: (_, __) => Text(
                                          'Pet Lover',
                                          style: theme.textTheme.headlineMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _AnimatedSection(
                    animation: _fadeAnimations[0],
                    child: _buildActivePetCard(context),
                  ),
                  const SizedBox(height: 24),
                  _AnimatedSection(
                    animation: _fadeAnimations[1],
                    child: Column(
                      children: [
                        _buildSectionHeader(
                          context,
                          'Upcoming',
                        ),
                        const SizedBox(height: 12),
                        _buildAppointmentsSection(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AnimatedSection(
                    animation: _fadeAnimations[2],
                    child: Column(
                      children: [
                        _buildSectionHeader(
                          context,
                          'Vaccine Status',
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VaccinesListScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildVaccineSummary(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AnimatedSection(
                    animation: _fadeAnimations[3],
                    child: Column(
                      children: [
                        _buildSectionHeader(
                          context,
                          'Active Medications',
                          onViewAll: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MedicationsListScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMedicationsSection(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onViewAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (onViewAll != null)
          _PulsingTextButton(
            onPressed: onViewAll,
            label: 'View All',
            theme: Theme.of(context),
          ),
      ],
    );
  }

  Widget _buildActivePetCard(BuildContext context) {
    final theme = Theme.of(context);
    final petsAsync = ref.watch(petNotifierProvider);

    return petsAsync.when(
      loading: () => _buildPetCardLoading(theme),
      error: (_, __) => _buildAddPetCard(theme),
      data: (pets) {
        if (pets.isEmpty) {
          return _buildAddPetCard(theme);
        }

        final totalPets = pets.length;
        final males = pets
            .where((p) => p.gender?.toLowerCase() == 'male')
            .length;
        final females = pets
            .where((p) => p.gender?.toLowerCase() == 'female')
            .length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Pets',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Text(
                          '$totalPets registered',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPetStat(theme, Icons.male, '$males', 'Male'),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    _buildPetStat(theme, Icons.female, '$females', 'Female'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPetStat(
    ThemeData theme,
    IconData icon,
    String count,
    String label,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPetCardLoading(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          3,
          (index) => Container(
            width: 60,
            height: 70,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddPetCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Your First Pet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start tracking your pet\'s health journey',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddEditPetScreen(),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('Add Pet'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsSection(BuildContext context) {
    final appointmentsAsync = ref.watch(appointmentNotifierProvider);

    return appointmentsAsync.when(
      loading: () => _buildAppointmentsLoading(),
      error: (_, __) => _buildNoAppointments(),
      data: (appointments) {
        final upcomingAppointments =
            appointments
                .where(
                  (a) =>
                      a.status == 'upcoming' &&
                      a.datetime.isAfter(DateTime.now()),
                )
                .toList()
              ..sort((a, b) => a.datetime.compareTo(b.datetime));

        if (upcomingAppointments.isEmpty) {
          return _buildNoAppointments();
        }

        return Column(
          children: upcomingAppointments.take(3).map((apt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAppointmentCard(
                context,
                apt.title,
                apt.datetime,
                Icons.calendar_today,
                Theme.of(context).colorScheme.primary,
                onTap: () async {
                  final hasAccess = await FeatureGate.check(
                    context: context,
                    ref: ref,
                    feature: 'appointments',
                    customMessage: 'View appointments with Paw Plan',
                  );
                  if (hasAccess && context.mounted) {
                    _showAppointmentBottomSheet(context, apt);
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentsLoading() {
    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoAppointments() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Theme.of(context).textTheme.labelLarge?.color ?? Colors.grey,
          ),
          const SizedBox(width: 12),
          Text(
            'No upcoming appointments',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    String title,
    DateTime? date,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
      width: double.infinity,
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.textTheme.labelMedium?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppDateUtils.formatShortDate(date),
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Upcoming',
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showAppointmentBottomSheet(BuildContext context, dynamic appointment) {
    final theme = Theme.of(context);
    final petsAsync = ref.read(petNotifierProvider);

    String petName = 'Unknown Pet';
    petsAsync.whenData((pets) {
      final pet = pets.where((p) => p.id == appointment.petId).firstOrNull;
      if (pet != null) petName = pet.name;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getAppointmentTypeIcon(appointment.type),
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Upcoming',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              theme,
              Icons.pets,
              'Pet',
              petName,
            ),
            _buildDetailRow(
              theme,
              Icons.calendar_today,
              'Date',
              AppDateUtils.formatFullDate(appointment.datetime),
            ),
            _buildDetailRow(
              theme,
              Icons.access_time,
              'Time',
              _formatTime(appointment.datetime),
            ),
            if (appointment.vetName != null && appointment.vetName!.isNotEmpty)
              _buildDetailRow(
                theme,
                Icons.person,
                'Vet',
                appointment.vetName!,
              ),
            if (appointment.clinicName != null && appointment.clinicName!.isNotEmpty)
              _buildDetailRow(
                theme,
                Icons.local_hospital,
                'Clinic',
                appointment.clinicName!,
              ),
            if (appointment.clinicPhone != null && appointment.clinicPhone!.isNotEmpty)
              _buildDetailRow(
                theme,
                Icons.phone,
                'Phone',
                appointment.clinicPhone!,
              ),
            if (appointment.clinicAddress != null && appointment.clinicAddress!.isNotEmpty)
              _buildDetailRow(
                theme,
                Icons.location_on,
                'Address',
                appointment.clinicAddress!,
              ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.textTheme.labelLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appointment.notes!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await _showConfirmDialog(
                        context,
                        'Cancel Appointment',
                        'Are you sure you want to cancel this appointment?',
                      );
                      if (confirm == true) {
                        await ref.read(appointmentNotifierProvider.notifier)
                            .cancelAppointment(appointment.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PawThemeData.alertRed,
                      side: BorderSide(color: PawThemeData.alertRed),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await ref.read(appointmentNotifierProvider.notifier)
                          .markAsCompleted(appointment.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PawThemeData.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.textTheme.labelLarge?.color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: PawThemeData.alertRed),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  IconData _getAppointmentTypeIcon(String? type) {
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

  Widget _buildVaccineSummary(BuildContext context) {
    final vaccinesAsync = ref.watch(vaccineNotifierProvider);

    return vaccinesAsync.when(
      loading: () => _buildVaccineSummaryLoading(context),
      error: (_, __) => _buildVaccineSummaryEmpty(context),
      data: (vaccines) {
        final activeVaccines = vaccines.where((v) => v.isActive).toList();

        int upToDate = 0;
        int dueSoon = 0;
        int overdue = 0;

        for (final v in activeVaccines) {
          switch (v.status) {
            case VaccineStatus.upToDate:
              upToDate++;
              break;
            case VaccineStatus.dueSoon:
              dueSoon++;
              break;
            case VaccineStatus.overdue:
              overdue++;
              break;
            default:
              break;
          }
        }

        if (activeVaccines.isEmpty) {
          return _buildVaccineSummaryEmpty(context);
        }

        return _buildVaccineSummaryContent(context, upToDate, dueSoon, overdue);
      },
    );
  }

  Widget _buildVaccineSummaryLoading(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 30,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildVaccineSummaryEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildVaccineChip(
              context,
              'Up to date',
              '0',
              Icons.check_circle,
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerTheme.color,
          ),
          Expanded(
            child: _buildVaccineChip(
              context,
              'Due soon',
              '0',
              Icons.schedule,
              Colors.orange,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerTheme.color,
          ),
          Expanded(
            child: _buildVaccineChip(
              context,
              'Overdue',
              '0',
              Icons.error,
              Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineSummaryContent(
    BuildContext context,
    int upToDate,
    int dueSoon,
    int overdue,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
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
          Expanded(
            child: _buildVaccineStatItem(
              context,
              'Up to date',
              upToDate.toString(),
              Icons.check_circle,
              theme.colorScheme.primary,
            ),
          ),
          Container(width: 1, height: 50, color: theme.dividerTheme.color),
          Expanded(
            child: _buildVaccineStatItem(
              context,
              'Due soon',
              dueSoon.toString(),
              Icons.schedule,
              Colors.orange,
            ),
          ),
          Container(width: 1, height: 50, color: theme.dividerTheme.color),
          Expanded(
            child: _buildVaccineStatItem(
              context,
              'Overdue',
              overdue.toString(),
              Icons.error,
              theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccineStatItem(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }

  Widget _buildVaccineChip(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }

  Widget _buildMedicationsSection(BuildContext context) {
    final medicationsAsync = ref.watch(medicationNotifierProvider);

    return medicationsAsync.when(
      loading: () => _buildMedicationsLoading(context),
      error: (_, __) => _buildMedicationsEmpty(context),
      data: (medications) {
        final activeMedications = medications.where((m) => m.isActive).toList();

        if (activeMedications.isEmpty) {
          return _buildMedicationsEmpty(context);
        }

        return _buildMedicationsContent(context, activeMedications);
      },
    );
  }

  Widget _buildMedicationsLoading(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsEmpty(BuildContext context) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.medication, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No active medications',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  'Add medications to track',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: theme.textTheme.labelLarge?.color),
        ],
      ),
    );
  }

  Widget _buildMedicationsContent(BuildContext context, List medications) {
    final theme = Theme.of(context);
    final displayMeds = medications.take(3).toList();

    return GestureDetector(
      onTap: () => _showMedicationsBottomSheet(context, medications),
      child: Container(
        padding: const EdgeInsets.all(20),
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
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.medication,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${medications.length} active medication${medications.length > 1 ? 's' : ''}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayMeds.map((m) => m.name).join(', '),
                    style: theme.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicationsBottomSheet(BuildContext context, List medications) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.medication,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Medications',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${medications.length} medication${medications.length > 1 ? 's' : ''}',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: medications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final med = medications[index];
                  return _buildMedicationCard(context, med, theme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, dynamic med, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  med.name ?? 'Unknown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: med.isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  med.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: med.isActive
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (med.dosage != null && med.dosage!.isNotEmpty)
            _buildMedInfoRow(
              theme,
              Icons.science_outlined,
              'Dosage',
              med.dosage!,
            ),
          if (med.frequency != null && med.frequency!.isNotEmpty)
            _buildMedInfoRow(
              theme,
              Icons.schedule,
              'Frequency',
              med.frequency!,
            ),
          if (med.startDate != null)
            _buildMedInfoRow(
              theme,
              Icons.calendar_today,
              'Started',
              AppDateUtils.formatShortDate(med.startDate!),
            ),
          if (med.prescribedBy != null && med.prescribedBy!.isNotEmpty)
            _buildMedInfoRow(
              theme,
              Icons.medical_services_outlined,
              'Prescribed by',
              med.prescribedBy!,
            ),
          if (med.notes != null && med.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    med.notes!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedSection({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;

  const _AnimatedIconButton({
    required this.icon,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(widget.icon, color: widget.theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _PulsingTextButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final ThemeData theme;

  const _PulsingTextButton({
    required this.onPressed,
    required this.label,
    required this.theme,
  });

  @override
  State<_PulsingTextButton> createState() => _PulsingTextButtonState();
}

class _PulsingTextButtonState extends State<_PulsingTextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: TextButton(
            onPressed: widget.onPressed,
            style: TextButton.styleFrom(
              foregroundColor: widget.theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }
}
