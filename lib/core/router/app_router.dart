import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../features/auth/landing_page.dart';
import '../../features/auth/login_screen.dart';
import '../../core/theme/app_theme_data.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/pets/pet_list_screen.dart';
import '../../features/pets/pet_profile_screen.dart';
import '../../features/records/records_list_screen.dart';
import '../../features/records/add_edit_record_screen.dart';
import '../../features/appointments/appointments_screen.dart';
import '../../features/vaccines/vaccines_list_screen.dart';
import '../../features/vaccines/add_edit_vaccine_screen.dart';
import '../../features/appointments/add_edit_appointment_screen.dart';
import '../../features/medications/medications_list_screen.dart';
import '../../features/medications/add_edit_medication_screen.dart';
import '../../features/weight/weight_history_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/theme_picker_screen.dart';
import '../../features/profile/test_notifications_screen.dart';
import '../../features/profile/help_faq_screen.dart';
import '../../features/profile/privacy_policy_screen.dart';
import '../../features/profile/terms_of_service_screen.dart';
import '../../features/billing/billing_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/';
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      if (!isLoggedIn && state.matchedLocation == '/home') {
        return '/';
      }
      if (!isLoggedIn && !isAuthRoute && !isOnboardingRoute) {
        return '/login';
      }
      
      if (isLoggedIn && isOnboardingRoute) {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          final userData = await supabase
              .from('users')
              .select('is_onboarding')
              .eq('id', user.id)
              .maybeSingle();
          
          final isOnboarding = userData?['is_onboarding'] as bool? ?? true;
          if (!isOnboarding) {
            return '/home';
          }
        }
      }
      
      if (isLoggedIn && (isAuthRoute || state.matchedLocation == '/')) {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        if (user != null) {
          final userData = await supabase
              .from('users')
              .select('is_onboarding')
              .eq('id', user.id)
              .maybeSingle();
          
          final isOnboarding = userData?['is_onboarding'] as bool? ?? true;
          if (isOnboarding) {
            return '/onboarding';
          }
        }
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/pets',
            builder: (context, state) => const PetListScreen(),
          ),
          GoRoute(
            path: '/pets/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PetProfileScreen(petId: id);
            },
          ),
          GoRoute(
            path: '/records',
            builder: (context, state) => const RecordsListScreen(),
          ),
          GoRoute(
            path: '/vaccines',
            builder: (context, state) => const VaccinesListScreen(),
          ),
          GoRoute(
            path: '/appointments',
            builder: (context, state) => const AppointmentsScreen(),
          ),
          GoRoute(
            path: '/medications',
            builder: (context, state) => const MedicationsListScreen(),
          ),
          GoRoute(
            path: '/weight/:petId',
            builder: (context, state) {
              final petId = state.pathParameters['petId']!;
              final petName = state.uri.queryParameters['name'] ?? 'Pet';
              return WeightHistoryScreen(petId: petId, petName: petName);
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/themes',
            builder: (context, state) => const ThemePickerScreen(),
          ),
          GoRoute(
            path: '/profile/test-notifications',
            builder: (context, state) => const TestNotificationsScreen(),
          ),
          GoRoute(
            path: '/profile/help-faq',
            builder: (context, state) => const HelpFaqScreen(),
          ),
          GoRoute(
            path: '/profile/privacy-policy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: '/profile/terms-of-service',
            builder: (context, state) => const TermsOfServiceScreen(),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) => const BillingScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/home') return 0;
    if (location.startsWith('/pets')) return 1;
    if (location.startsWith('/records')) return 2;
    if (location.startsWith('/appointments')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) async {
    if (index != _currentIndex) {
      await _controller.forward();
      await _controller.reverse();
      setState(() => _currentIndex = index);
    }
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/pets');
        break;
      case 2:
        context.go('/records');
        break;
      case 3:
        context.go('/appointments');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    _currentIndex = selectedIndex;
    final theme = Theme.of(context);

    final navItems = [
      _NavItemData(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      _NavItemData(icon: Icons.pets_outlined, activeIcon: Icons.pets, label: 'Pets'),
      _NavItemData(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Records'),
      _NavItemData(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Appts'),
      _NavItemData(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    ];

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final isSelected = index == selectedIndex;
                return _DuolingoNavItem(
                  icon: navItems[index].icon,
                  activeIcon: navItems[index].activeIcon,
                  label: navItems[index].label,
                  isSelected: isSelected,
                  theme: theme,
                  onTap: () => _onItemTapped(index, context),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItemData({required this.icon, required this.activeIcon, required this.label});
}

class _DuolingoNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DuolingoNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_DuolingoNavItem> createState() => _DuolingoNavItemState();
}

class _DuolingoNavItemState extends State<_DuolingoNavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_DuolingoNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward(from: 0);
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, _bounceAnimation.value),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? widget.theme.colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        widget.isSelected ? widget.activeIcon : widget.icon,
                        color: widget.isSelected
                            ? widget.theme.colorScheme.primary
                            : widget.theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: widget.isSelected ? 12 : 11,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: widget.isSelected
                        ? widget.theme.colorScheme.primary
                        : widget.theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
