import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/upgrade_modal.dart';

class FeatureGate {
  static Future<bool> check({
    required BuildContext context,
    required WidgetRef ref,
    required String feature,
    String? customMessage,
    bool showModal = true,
  }) async {
    final userAsync = ref.read(userProvider);

    final canAccess = userAsync.maybeWhen(
      data: (user) => _canAccessFeature(user?.plan ?? 'free', feature),
      orElse: () => false,
    );

    if (!canAccess && showModal) {
      await UpgradeModal.showForFeature(
        context,
        feature,
        message: customMessage,
      );
    }

    return canAccess;
  }

  static bool _canAccessFeature(String plan, String feature) {
    final isPro = plan == 'pro' || plan == 'premium';
    final isPremium = plan == 'premium';

    switch (feature) {
      case 'appointments':
        return isPro;
      case 'records':
        return isPro;
      case 'unlimited_records':
        return isPro;
      case 'file_upload':
        return isPro;
      case 'vaccine_reminders':
        return isPro;
      case 'push_notifications':
        return isPro;
      case 'pdf_export':
        return isPremium;
      case 'multiple_pets':
        return isPro;
      case 'unlimited_pets':
        return isPremium;
      default:
        return true;
    }
  }

  static Future<void> guard({
    required BuildContext context,
    required WidgetRef ref,
    required String feature,
    String? customMessage,
    required void Function() onAllowed,
  }) async {
    final canAccess = await check(
      context: context,
      ref: ref,
      feature: feature,
      customMessage: customMessage,
    );

    if (canAccess) {
      onAllowed();
    }
  }
}

class PlanUtils {
  static bool canAccessFeature(String? plan, String feature) {
    return _canAccessFeature(plan ?? 'free', feature);
  }

  static bool _canAccessFeature(String plan, String feature) {
    final isPro = plan == 'pro' || plan == 'premium';
    final isPremium = plan == 'premium';

    switch (feature) {
      case 'appointments':
        return isPro;
      case 'records':
        return isPro;
      case 'unlimited_records':
        return isPro;
      case 'file_upload':
        return isPro;
      case 'vaccine_reminders':
        return isPro;
      case 'push_notifications':
        return isPro;
      case 'pdf_export':
        return isPremium;
      case 'multiple_pets':
        return isPro;
      case 'unlimited_pets':
        return isPremium;
      default:
        return true;
    }
  }

  static bool isPaidPlan(String? plan) {
    return plan == 'pro' || plan == 'premium';
  }

  static bool isPremiumPlan(String? plan) {
    return plan == 'premium';
  }

  static String getPlanName(String? plan) {
    switch (plan) {
      case 'pro':
        return 'Pro Plan';
      case 'premium':
        return 'Premium Plan';
      default:
        return 'Free';
    }
  }
}
