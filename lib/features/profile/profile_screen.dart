import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme_data.dart';
import '../../shared/providers/auth_notifier.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/widgets/paw_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeNotifierProvider);
    final themeData = PawThemeData.all[currentTheme]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PawCard(
            child: Column(
              children: [
                user.when(
                  data: (u) => Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        u?.fullName ?? 'Pet Lover',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        u?.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.labelLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPlanBadge(context, u?.plan ?? 'free'),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'APP SETTINGS'),
          const SizedBox(height: 12),
          PawCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('App Theme'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(themeData.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        themeData.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.labelLarge?.color,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => context.push('/profile/themes'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/test-notifications'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.straighten),
                  title: const Text('Weight Units'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.labelLarge?.color,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'SUBSCRIPTION'),
          const SizedBox(height: 12),
          PawCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('Your Plan'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Free',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.labelLarge?.color,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Purchases'),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Manage Subscription'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'SUPPORT & LEGAL'),
          const SizedBox(height: 12),
          PawCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & FAQ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Rate PawPass'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'ACCOUNT'),
          const SizedBox(height: 12),
          PawCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.logout, color: PawThemeData.alertAmber),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(color: PawThemeData.alertAmber),
                  ),
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: PawThemeData.alertRed),
                  title: Text(
                    'Delete Account',
                    style: TextStyle(color: PawThemeData.alertRed),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildPlanBadge(BuildContext context, String plan) {
    final theme = Theme.of(context);
    Color bgColor;
    Color textColor;
    String label;

    switch (plan) {
      case 'pro':
        bgColor = theme.colorScheme.secondary;
        textColor = theme.colorScheme.primary;
        label = 'Paw Plan';
        break;
      case 'family':
        bgColor = theme.colorScheme.primary;
        textColor = Colors.white;
        label = 'Family Plan';
        break;
      default:
        bgColor = Colors.transparent;
        textColor = theme.textTheme.labelLarge?.color ?? Colors.grey;
        label = 'Free';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: plan == 'free'
            ? Border.all(color: theme.dividerTheme.color ?? Colors.grey)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
