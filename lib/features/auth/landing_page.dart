import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;

  final ScrollController _scrollController = ScrollController();
  final List<AnimationController> _featureControllers = [];
  final List<bool> _featureAnimated = [];

  final List<_FeatureItem> _features = [
    _FeatureItem(
      icon: Icons.pets,
      title: 'Pet Profiles',
      description:
          'Create detailed profiles for all your furry friends with photos, breed info, and medical history.',
      animationAsset: 'assets/animations/Happy Dog.json',
    ),
    _FeatureItem(
      icon: Icons.vaccines,
      title: 'Vaccine Tracker',
      description:
          'Never miss a vaccine! Get reminders for upcoming shots and keep your pet protected.',
      animationAsset: 'assets/animations/Hand with syringe monkeypox vaccine.json',
    ),
    _FeatureItem(
      icon: Icons.calendar_month,
      title: 'Appointments',
      description:
          'Schedule vet visits, grooming sessions, and more. Get reminded before any appointment.',
      animationAsset: 'assets/animations/Prescription docAppoint.json',
    ),
    _FeatureItem(
      icon: Icons.description,
      title: 'Health Records',
      description:
          'Store vet reports, lab results, and medical documents all in one place.',
      animationAsset: 'assets/animations/Tablet Management.json',
    ),
    _FeatureItem(
      icon: Icons.medication,
      title: 'Medications',
      description:
          'Track prescriptions and dosages. Never miss giving your pet their medicine.',
      animationAsset: 'assets/animations/Cat Playing.json',
    ),
    _FeatureItem(
      icon: Icons.monitor_weight,
      title: 'Weight Tracking',
      description:
          'Monitor your pet\'s weight over time with easy charts and insights.',
      animationAsset: 'assets/animations/Goldfish.json',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _heroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );
    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroController, curve: Curves.easeOut));

    for (int i = 0; i < _features.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      _featureControllers.add(controller);
      _featureAnimated.add(false);
    }

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heroController.forward();
    });
  }

  void _onScroll() {
    if (!mounted) return;

    for (int i = 0; i < _features.length; i++) {
      final key = _featureKeys[i];
      if (key?.currentContext != null && !_featureAnimated[i]) {
        final box = key!.currentContext!.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero).dy;
        final screenHeight = MediaQuery.of(context).size.height;

        if (position < screenHeight * 0.8) {
          _featureAnimated[i] = true;
          _featureControllers[i].forward();
        }
      }
    }
  }

  final Map<int, GlobalKey?> _featureKeys = {};

  @override
  void dispose() {
    _heroController.dispose();
    _scrollController.dispose();
    for (final controller in _featureControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    for (int i = 0; i < _features.length; i++) {
      _featureKeys[i] ??= GlobalKey();
    }

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroSection(theme),
          ),
          SliverToBoxAdapter(
            child: _buildFeaturesHeader(theme),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFeatureCard(theme, index),
              childCount: _features.length,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildCTA(theme),
          ),
          SliverToBoxAdapter(
            child: _buildFooter(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _heroFadeAnimation,
            child: SlideTransition(
              position: _heroSlideAnimation,
              child: SizedBox(
                height: 220,
              child: Lottie.asset(
                'assets/animations/Happy Cat.json',
                fit: BoxFit.contain,
              ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeTransition(
            opacity: _heroFadeAnimation,
            child: Column(
              children: [
                Text(
                  '🐾 PawPass',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Pet\'s Digital Health Passport',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Track vaccinations, appointments, health records & more.\nEverything your pet needs, in one place.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          FadeTransition(
            opacity: _heroFadeAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push('/register'),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Get Started'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: _heroFadeAnimation,
            child: Text(
              'Free to start • No credit card required',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Everything Your Pet Needs',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your pet\'s health with ease',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(ThemeData theme, int index) {
    final feature = _features[index];
    final isEven = index % 2 == 0;

    return Padding(
      key: _featureKeys[index],
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: AnimatedBuilder(
        animation: _featureControllers[index],
        builder: (context, child) {
          final value = _featureControllers[index].value;
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isEven) ...[
              Expanded(
                child: _FeatureContent(
                  feature: feature,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              _FeatureAnimation(animationAsset: feature.animationAsset),
            ] else ...[
              _FeatureAnimation(animationAsset: feature.animationAsset),
              const SizedBox(width: 16),
              Expanded(
                child: _FeatureContent(
                  feature: feature,
                  theme: theme,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCTA(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Ready to get started?',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Join thousands of pet owners who trust PawPass\nfor their pet\'s health journey.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: const Text('Create Free Account'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Already have an account?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push('/login'),
            child: const Text('Sign In'),
          ),
          const SizedBox(height: 24),
          Text(
            '© 2026 PawPass',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final String animationAsset;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.animationAsset,
  });
}

class _FeatureContent extends StatelessWidget {
  final _FeatureItem feature;
  final ThemeData theme;

  const _FeatureContent({
    required this.feature,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            feature.icon,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          feature.title,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          feature.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _FeatureAnimation extends StatelessWidget {
  final String animationAsset;

  const _FeatureAnimation({required this.animationAsset});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Lottie.asset(
        animationAsset,
        fit: BoxFit.contain,
      ),
    );
  }
}
