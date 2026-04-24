import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/pet_model.dart';
import '../../data/models/vaccine_model.dart';
import '../../shared/providers/pet_provider.dart';
import '../../shared/providers/vaccine_provider.dart';
import '../../shared/providers/medication_provider.dart';
import '../../shared/providers/record_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/paw_card.dart';
import '../../core/utils/feature_gate.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/sharing_service.dart';
import '../../core/services/id_card_service.dart';
import '../../core/theme/app_theme_data.dart';
import '../../features/vaccines/vaccines_list_screen.dart';
import '../../features/medications/medications_list_screen.dart';
import '../../features/weight/weight_history_screen.dart';
import '../../features/billing/billing_screen.dart';
import '../../shared/widgets/pet_id_card_widget.dart';
import 'add_edit_pet_screen.dart';

class _TailPainter extends CustomPainter {
  final Color color;

  _TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.6, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PetProfileScreen extends ConsumerWidget {
  final String petId;
  static final GlobalKey idCardKey = GlobalKey();

  const PetProfileScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petNotifierProvider);

    return petsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (pets) {
        final pet = pets.where((p) => p.id == petId).firstOrNull;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Pet not found')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, ref, pet),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickStats(context, ref, pet),
                      const SizedBox(height: 24),
                      _buildDetailsSection(context, pet),
                      const SizedBox(height: 24),
                      _buildHealthSummary(context, ref, pet),
                      const SizedBox(height: 24),
                      _buildQuickActions(context, ref, pet),
                      const SizedBox(height: 24),
                      if (pet.notes != null && pet.notes!.isNotEmpty) ...[
                        _buildNotesSection(context, pet),
                        const SizedBox(height: 24),
                      ],
                      _buildShareSection(context, ref, pet),
                      const SizedBox(height: 24),
                      _buildDangerZone(context, ref, pet),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref, Pet pet) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            if (pet.photoUrl != null)
              Image.network(
                pet.photoUrl!,
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.overlay,
                color: Colors.black.withValues(alpha: 0.3),
              )
            else
              Center(
                child: Text(
                  pet.speciesEmoji,
                  style: const TextStyle(fontSize: 100),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${pet.species}${pet.breed != null ? ' • ${pet.breed}' : ''}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditPetScreen(pet: pet),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref, Pet pet) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.cake,
            label: 'Age',
            value: pet.ageString,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.monitor_weight,
            label: 'Weight',
            value: pet.weightKg != null ? '${pet.weightKg} kg' : '--',
            color: PawThemeData.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: pet.gender == 'male' ? Icons.male : Icons.female,
            label: 'Gender',
            value: _formatGender(pet.gender),
            color: pet.gender == 'male' ? Colors.blue : Colors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.labelLarge?.color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, Pet pet) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(context, 'Breed', pet.breed ?? 'Not specified'),
          _buildDivider(context),
          _buildDetailRow(context, 'Color', pet.color ?? 'Not specified'),
          _buildDivider(context),
          _buildDetailRow(context, 'Neutered', pet.neutered ? 'Yes' : 'No'),
          _buildDivider(context),
          _buildDetailRow(
            context,
            'Microchip',
            pet.microchip ?? 'Not specified',
          ),
          if (pet.dob != null) ...[
            _buildDivider(context),
            _buildDetailRow(
              context,
              'Birthday',
              '${pet.dob!.day}/${pet.dob!.month}/${pet.dob!.year}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      color: Theme.of(context).dividerTheme.color?.withValues(alpha: 0.3),
    );
  }

  Widget _buildHealthSummary(BuildContext context, WidgetRef ref, Pet pet) {
    final theme = Theme.of(context);
    final vaccinesAsync = ref.watch(vaccineNotifierProvider);
    final medicationsAsync = ref.watch(medicationNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Summary',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: vaccinesAsync.when(
                data: (vaccines) {
                  final petVaccines = vaccines.where((v) => v.petId == pet.id).toList();
                  final overdue = petVaccines.where((v) => v.status == VaccineStatus.overdue).length;
                  final dueSoon = petVaccines.where((v) => v.status == VaccineStatus.dueSoon).length;
                  Color statusColor; String statusText;
                  if (overdue > 0) { statusColor = Colors.red; statusText = '$overdue'; }
                  else if (dueSoon > 0) { statusColor = Colors.orange; statusText = '$dueSoon'; }
                  else { statusColor = PawThemeData.successGreen; statusText = 'OK'; }
                  return _buildMiniHealthCard(icon: Icons.vaccines, title: 'Vaccines', value: '${petVaccines.length}', status: statusText, statusColor: statusColor, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VaccinesListScreen(initialPetId: pet.id))));
                },
                loading: () => _buildMiniHealthCard(icon: Icons.vaccines, title: 'Vaccines', value: '-', status: '...', statusColor: Colors.grey, onTap: () {}),
                error: (_, __) => _buildMiniHealthCard(icon: Icons.vaccines, title: 'Vaccines', value: '!', status: 'Error', statusColor: Colors.red, onTap: () {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: medicationsAsync.when(
                data: (medications) {
                  final activeMeds = medications.where((m) => m.petId == pet.id && m.isActive).length;
                  return _buildMiniHealthCard(icon: Icons.medication, title: 'Meds', value: '$activeMeds', status: activeMeds > 0 ? 'Active' : 'None', statusColor: activeMeds > 0 ? theme.colorScheme.primary : PawThemeData.successGreen, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicationsListScreen(initialPetId: pet.id))));
                },
                loading: () => _buildMiniHealthCard(icon: Icons.medication, title: 'Meds', value: '-', status: '...', statusColor: Colors.grey, onTap: () {}),
                error: (_, __) => _buildMiniHealthCard(icon: Icons.medication, title: 'Meds', value: '!', status: 'Error', statusColor: Colors.red, onTap: () {}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMiniHealthCard(icon: Icons.monitor_weight, title: 'Weight', value: pet.weightKg != null ? '${pet.weightKg!.toStringAsFixed(1)}' : '-', status: pet.weightKg != null ? 'kg' : 'Not set', statusColor: pet.weightKg != null ? PawThemeData.successGreen : Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WeightHistoryScreen(petId: pet.id, petName: pet.name)))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniHealthCard({required IconData icon, required String title, required String value, required String status, required Color statusColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: statusColor),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int count,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
    bool hasTail = false,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: hasTail ? Radius.zero : Radius.circular(20),
            bottomRight: hasTail ? Radius.zero : Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: theme.textTheme.labelLarge?.color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (hasTail)
              Positioned(
                bottom: -1,
                left: 16,
                child: CustomPaint(
                  size: Size(20, 10),
                  painter: _TailPainter(color: theme.colorScheme.surface),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, Pet pet) {
    final theme = Theme.of(context);

    return PawCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildActionTile(
            context,
            icon: Icons.credit_card,
            title: 'Export ID Card',
            subtitle: 'Download as PNG image',
            iconColor: theme.colorScheme.primary,
            iconBgColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            onTap: () => _exportPdf(context, ref, pet),
            isHighlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: isHighlighted
            ? BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.labelLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Pet pet) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.notes,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Notes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pet.notes!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareSection(BuildContext context, WidgetRef ref, Pet pet) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(userProvider);

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (user) {
        if (user == null || user.plan == 'free') {
          return _buildUpgradePrompt(context);
        }
        return _buildShareCard(context, ref, pet);
      },
    );
  }

  Widget _buildUpgradePrompt(BuildContext context) {
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.lock_outline,
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
                      'Share Passport Online',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Pro: Share via link for vets & sitters',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.labelLarge?.color,
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
            child: ElevatedButton(
              onPressed: () => context.push('/billing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Upgrade to Pro'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareCard(BuildContext context, WidgetRef ref, Pet pet) {
    final theme = Theme.of(context);
    final shareUrl = pet.shareLink;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.share,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Share Passport',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: pet.isSharingEnabled,
                onChanged: (value) => _toggleSharing(context, ref, pet, value),
              ),
            ],
          ),
          if (pet.isSharingEnabled && shareUrl.isNotEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: QrImageView(
                data: shareUrl,
                version: QrVersions.auto,
                size: 150,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                shareUrl,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyLink(context, shareUrl),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareLink(context, shareUrl),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _previewPassport(context, shareUrl),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _regenerateLink(context, ref, pet),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Regenerate Link'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleSharing(
      BuildContext context, WidgetRef ref, Pet pet, bool enabled) async {
    final theme = Theme.of(context);
    final sharingService = SharingService();
    try {
      if (enabled) {
        await sharingService.enableSharing(pet.id);
      } else {
        await sharingService.disableSharing(pet.id);
      }
      ref.invalidate(petNotifierProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled
                ? 'Sharing enabled'
                : 'Sharing disabled'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyLink(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _previewPassport(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _regenerateLink(
      BuildContext context, WidgetRef ref, Pet pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Link?'),
        content: const Text(
          'This will invalidate the current share link. Anyone using the old link will no longer be able to view the passport.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final sharingService = SharingService();
      await sharingService.regenerateToken(pet.id);
      ref.invalidate(petNotifierProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link regenerated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref, Pet pet) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delete Pet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'This action cannot be undone',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.labelLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context, ref, pet),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Pet?'),
        content: Text(
          'Are you sure you want to delete ${pet.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(petNotifierProvider.notifier).deletePet(pet.id);
              if (context.mounted) {
                context.go('/pets');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
);
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref, Pet pet) async {
    final hasAccess = await FeatureGate.check(
      context: context,
      ref: ref,
      feature: 'pdf_export',
    );

    if (!hasAccess) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Export ID Card'),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        insetPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: PetIdCardWidget(pet: pet, cardKey: idCardKey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await IdCardService.shareCard(
                cardKey: idCardKey,
                petName: pet.name,
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'Unknown';
    return gender[0].toUpperCase() + gender.substring(1);
  }
}
