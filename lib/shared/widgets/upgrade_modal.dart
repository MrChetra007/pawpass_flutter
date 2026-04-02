import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme_data.dart';

class UpgradeModal extends StatelessWidget {
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

  String _getFeatureMessage() {
    if (customMessage != null) return customMessage!;

    switch (featureName) {
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
    if (customTitle != null) return customTitle!;

    switch (featureName) {
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
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerTheme.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.pets,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(_getDefaultTitle(), style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              _getFeatureMessage(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.labelLarge?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildPlanCard(
              context,
              'Paw Plan',
              '\$4.99/mo',
              _getPawPlanFeatures(),
              false,
            ),
            const SizedBox(height: 12),
            _buildPlanCard(
              context,
              'Family Plan',
              '\$9.99/mo',
              _getFamilyPlanFeatures(),
              true,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: TextStyle(color: theme.textTheme.labelLarge?.color),
              ),
            ),
            const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }

  List<String> _getPawPlanFeatures() {
    switch (featureName) {
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
    switch (featureName) {
      case 'pdf_export':
        return ['PDF passport export', 'Family sharing', 'Everything in Paw'];
      case 'family_sharing':
        return ['Family sharing', 'Unlimited pets', 'Priority support'];
      default:
        return [
          'Unlimited pets',
          'PDF exports',
          'Family sharing',
          'Priority support',
        ];
    }
  }

  Widget _buildPlanCard(
    BuildContext context,
    String name,
    String price,
    List<String> features,
    bool isBestValue,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        context.push('/billing');
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isBestValue
                ? theme.colorScheme.primary
                : theme.dividerTheme.color ?? Colors.grey,
            width: isBestValue ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            if (isBestValue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        price,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
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
                          const SizedBox(width: 8),
                          Text(f, style: theme.textTheme.bodyMedium),
                        ],
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
