import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme_data.dart';
import '../../shared/providers/auth_notifier.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/providers/theme_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeNotifierProvider);
    final themeData = PawThemeData.all[currentTheme]!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
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
                      Text('Profile', style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('Manage your account', style: theme.textTheme.labelLarge),
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
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildProfileCard(context, user, theme),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSectionHeader(context, 'APP SETTINGS'),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSettingsCard(context, theme, themeData),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSectionHeader(context, 'SUBSCRIPTION'),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSubscriptionCard(context, theme),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSectionHeader(context, 'SUPPORT & LEGAL'),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSupportCard(context, theme),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildSectionHeader(context, 'ACCOUNT'),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildAccountCard(context, theme, ref),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AsyncValue user, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          user.when(
            data: (u) => Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  u?.fullName ?? 'Pet Lover',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  u?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.labelLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPlanBadge(context, u?.plan ?? 'free'),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error loading profile'),
          ),
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

  Widget _buildSettingsCard(BuildContext context, ThemeData theme, PawThemeData themeData) {
    return Container(
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
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: 'App Theme',
            subtitle: '${themeData.emoji} ${themeData.name}',
            onTap: () => context.push('/profile/themes'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () => context.push('/profile/test-notifications'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            context,
            icon: Icons.straighten,
            title: 'Weight Units',
            subtitle: 'kg',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, ThemeData theme) {
    return Container(
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
          _buildSettingsTile(
            context,
            icon: Icons.credit_card,
            title: 'Your Plan',
            subtitle: 'Free',
            onTap: () => context.push('/billing'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            context,
            icon: Icons.restore,
            title: 'Restore Purchases',
            onTap: () => context.push('/billing'),
          ),
          _buildDivider(),
          _buildSettingsTile(
            context,
            icon: Icons.settings,
            title: 'Manage Subscription',
            onTap: () => context.push('/billing'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, ThemeData theme) {
    return Container(
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
          _buildSettingsTile(context, icon: Icons.help_outline, title: 'Help & FAQ', onTap: () {}),
          _buildDivider(),
          _buildSettingsTile(context, icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
          _buildDivider(),
          _buildSettingsTile(context, icon: Icons.description_outlined, title: 'Terms of Service', onTap: () {}),
          _buildDivider(),
          _buildSettingsTile(context, icon: Icons.star_outline, title: 'Rate PawPass', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, ThemeData theme, WidgetRef ref) {
    return Container(
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
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Sign Out',
            iconColor: PawThemeData.alertAmber,
            textColor: PawThemeData.alertAmber,
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            context,
            icon: Icons.delete_outline,
            title: 'Delete Account',
            iconColor: PawThemeData.alertRed,
            textColor: PawThemeData.alertRed,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.labelLarge?.color,
                  ),
                ),
              if (subtitle == null)
                Icon(
                  Icons.chevron_right,
                  color: theme.textTheme.labelLarge?.color,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Colors.black.withValues(alpha: 0.05),
    );
  }

  Widget _buildPlanBadge(BuildContext context, String plan) {
    final theme = Theme.of(context);
    Color bgColor;
    Color textColor;
    String label;

    switch (plan) {
      case 'pro':
        bgColor = theme.colorScheme.primary;
        textColor = Colors.white;
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
        label = 'Free Plan';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
