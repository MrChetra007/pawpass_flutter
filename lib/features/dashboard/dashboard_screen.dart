import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/vaccine_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/vaccine_provider.dart';
import '../../shared/providers/appointment_provider.dart';
import '../../shared/providers/medication_provider.dart';
import '../../features/vaccines/vaccines_list_screen.dart';
import '../../features/medications/medications_list_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: theme.textTheme.labelMedium,
            ),
            Text(
              'Pet Lover',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(petNotifierProvider);
          ref.invalidate(vaccineNotifierProvider);
          ref.invalidate(appointmentNotifierProvider);
          ref.invalidate(medicationNotifierProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActivePetCard(context),
              const SizedBox(height: 24),
              _buildSectionHeader(
                context,
                'Upcoming Appointments',
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VaccinesListScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildAppointmentsSection(context),
              const SizedBox(height: 24),
              _buildSectionHeader(
                context,
                'Vaccine Status',
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VaccinesListScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildVaccineSummary(context),
              const SizedBox(height: 24),
              _buildSectionHeader(
                context,
                'Active Medications',
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MedicationsListScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildMedicationsSection(context),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
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
        final males = pets.where((p) => p.gender?.toLowerCase() == 'male').length;
        final females = pets.where((p) => p.gender?.toLowerCase() == 'female').length;

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPetStat(theme, '🐶🐱', '$totalPets', 'Total'),
              _buildPetStat(theme, '♂️', '$males', 'Male'),
              _buildPetStat(theme, '♀️', '$females', 'Female'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPetStat(ThemeData theme, String emoji, String count, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 8),
        Text(
          count,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
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
        children: List.generate(3, (index) => Container(
          width: 60,
          height: 70,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
        )),
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
              onPressed: () {},
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
        final upcomingAppointments = appointments
            .where((a) => a.status == 'upcoming' && a.datetime.isAfter(DateTime.now()))
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
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentsLoading() {
    return Column(
      children: List.generate(2, (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      )),
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
    Color color,
  ) {
    return Container(
      width: double.infinity,
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppDateUtils.formatShortDate(date),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
          Container(width: 1, height: 40, color: Theme.of(context).dividerTheme.color),
          Expanded(
            child: _buildVaccineChip(
              context,
              'Due soon',
              '0',
              Icons.schedule,
              Colors.orange,
            ),
          ),
          Container(width: 1, height: 40, color: Theme.of(context).dividerTheme.color),
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

  Widget _buildVaccineSummaryContent(BuildContext context, int upToDate, int dueSoon, int overdue) {
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
              upToDate.toString(),
              Icons.check_circle,
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Container(width: 1, height: 40, color: Theme.of(context).dividerTheme.color),
          Expanded(
            child: _buildVaccineChip(
              context,
              'Due soon',
              dueSoon.toString(),
              Icons.schedule,
              Colors.orange,
            ),
          ),
          Container(width: 1, height: 40, color: Theme.of(context).dividerTheme.color),
          Expanded(
            child: _buildVaccineChip(
              context,
              'Overdue',
              overdue.toString(),
              Icons.error,
              Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
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
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
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
            child: Icon(
              Icons.medication,
              color: theme.colorScheme.primary,
            ),
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
          Icon(
            Icons.chevron_right,
            color: theme.textTheme.labelLarge?.color,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsContent(BuildContext context, List medications) {
    final theme = Theme.of(context);
    final displayMeds = medications.take(3).toList();

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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${medications.length} active medication${medications.length > 1 ? 's' : ''}',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      displayMeds.map((m) => m.name).join(', '),
                      style: theme.textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.textTheme.labelLarge?.color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickAction(
            context,
            'Add Record',
            Icons.description,
            () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            context,
            'Log Weight',
            Icons.monitor_weight,
            () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickAction(
            context,
            'Appointment',
            Icons.calendar_month,
            () {},
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondary.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
