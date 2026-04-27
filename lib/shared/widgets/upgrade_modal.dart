import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme_data.dart';

class UpgradeModal extends StatefulWidget {
  final String? featureName;
  final String? customTitle;
  final String? customMessage;

  const UpgradeModal({
    super.key,
    this.featureName,
    this.customTitle,
    this.customMessage,
  });

  static Future<void> show(
    BuildContext context, {
    String? featureName,
    String? customTitle,
    String? customMessage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradeModal(
        featureName: featureName,
        customTitle: customTitle,
        customMessage: customMessage,
      ),
    );
  }

  static Future<void> showForFeature(
    BuildContext context,
    String feature, {
    String? message,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          UpgradeModal(featureName: feature, customMessage: message),
    );
  }

  @override
  State<UpgradeModal> createState() => _UpgradeModalState();
}

class _UpgradeModalState extends State<UpgradeModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
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

  String _getFeatureMessage() {
    if (widget.customMessage != null) return widget.customMessage!;

    switch (widget.featureName) {
      case 'appointments':
        return 'Create and manage appointments with Paw Plan';
      case 'records':
        return 'Add unlimited health records with Paw Plan';
      case 'file_upload':
        return 'Upload files and documents with Paw Plan';
      case 'vaccine_reminders':
        return 'Get vaccine reminders with Paw Plan';
      case 'pdf_export':
        return 'Export PDF passports with Family Plan';
      case 'family_sharing':
        return 'Share with family members with Family Plan';
      case 'multiple_pets':
        return 'Add more than 1 pet with Paw Plan';
      default:
        return 'Unlock this feature with a premium plan';
    }
  }

  String _getDefaultTitle() {
    if (widget.customTitle != null) return widget.customTitle!;

    switch (widget.featureName) {
      case 'appointments':
        return 'Unlock Appointments';
      case 'records':
        return 'Unlock Unlimited Records';
      case 'file_upload':
        return 'Unlock File Uploads';
      case 'vaccine_reminders':
        return 'Unlock Reminders';
      case 'pdf_export':
        return 'Unlock PDF Export';
      case 'family_sharing':
        return 'Unlock Family Sharing';
      case 'multiple_pets':
        return 'Add More Pets';
      default:
        return 'Upgrade to Pro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerTheme.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.pets,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getDefaultTitle(),
                              style: theme.textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getFeatureMessage(),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.textTheme.labelLarge?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildPlanCard(
                            context,
                            title: 'Pro Plan',
                            price: '\$2.99',
                            period: '/month',
                            description: 'Perfect for single pet owners',
                            isPopular: false,
                            features: _getPawPlanFeatures(),
                            onTap: () => _navigateToBilling(),
                          ),
                          const SizedBox(height: 16),
                          _buildPlanCard(
                            context,
                            title: 'Premium Plan',
                            price: '\$4.99',
                            period: '/month',
                            description: 'Best value for multiple pets',
                            isPopular: true,
                            features: _getFamilyPlanFeatures(),
                            onTap: () => _navigateToBilling(),
                          ),
                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Maybe Later',
                                style: TextStyle(
                                  color: theme.textTheme.labelLarge?.color,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/billing');
                              },
                              child: Text(
                                'View Full Pricing',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBilling() {
    Navigator.pop(context);
    context.push('/billing');
  }

  List<String> _getPawPlanFeatures() {
    switch (widget.featureName) {
      case 'appointments':
        return ['Create appointments', 'Get reminders', 'Up to 3 pets'];
      case 'records':
        return ['Unlimited records', 'File uploads', 'Up to 3 pets'];
      case 'multiple_pets':
        return ['Up to 3 pets', 'Unlimited records', 'All features'];
      case 'file_upload':
        return ['File uploads', 'Document storage', 'Up to 3 pets'];
      default:
        return ['3 pets', 'Unlimited records', 'File uploads', 'Reminders'];
    }
  }

  List<String> _getFamilyPlanFeatures() {
    switch (widget.featureName) {
      case 'pdf_export':
        return [
          'PDF passport export',
          'everything paw plan',
          'Everything in Pro',
        ];
      case 'family_sharing':
        return ['everything paw plan', 'Unlimited pets', 'Priority support'];
      default:
        return [
          'Unlimited pets',
          'PDF exports',
          'everything paw plan',
          'Priority support',
        ];
    }
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String price,
    required String period,
    required String description,
    required bool isPopular,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: isPopular
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                  ),
                ),
                child: Center(
                  child: Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(description, style: theme.textTheme.labelMedium),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                price,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(period, style: theme.textTheme.labelMedium),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...features.map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: PawThemeData.successGreen.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: PawThemeData.successGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
                        foregroundColor: isPopular
                            ? Colors.white
                            : theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        title == 'Pro Plan'
                            ? 'Upgrade to Pro Plan'
                            : 'Upgrade to Premium Plan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
