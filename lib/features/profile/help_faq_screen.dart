import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme_data.dart';
import '../../shared/providers/theme_provider.dart';

class HelpFaqScreen extends ConsumerStatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  ConsumerState<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends ConsumerState<HelpFaqScreen> {
  final Map<String, bool> _expandedItems = {};

  final List<_FaqCategory> _categories = [
    _FaqCategory(
      title: 'Getting Started',
      icon: Icons.rocket_launch_outlined,
      faqs: [
        _FaqItem(
          question: 'How do I add my first pet?',
          answer: 'Go to the Pets tab and tap the + button. Fill in your pet\'s details like name, species, breed, and date of birth. You can also add a photo from your gallery or camera.',
        ),
        _FaqItem(
          question: 'Can I use PawPass for multiple pets?',
          answer: 'Yes! Free users can add 1 pet. Paw Plan users can add up to 3 pets, and Family Plan users can add unlimited pets.',
        ),
        _FaqItem(
          question: 'How do I switch between my pets?',
          answer: 'Tap on your pet\'s name or avatar at the top of the Dashboard to open the pet switcher and select a different pet.',
        ),
      ],
    ),
    _FaqCategory(
      title: 'Health Records',
      icon: Icons.medical_services_outlined,
      faqs: [
        _FaqItem(
          question: 'What types of health records can I store?',
          answer: 'You can store checkups, surgeries, illnesses, injuries, dental records, grooming sessions, lab results, and other medical records.',
        ),
        _FaqItem(
          question: 'How do I upload documents?',
          answer: 'When adding or editing a record, tap on the document attachment area to pick a file from your device. Document uploads are available for Paw Plan and Family Plan users.',
        ),
        _FaqItem(
          question: 'Can I track vaccination due dates?',
          answer: 'Yes! Add vaccines with their due dates and PawPass will show status badges: green for up-to-date, yellow for due soon (within 30 days), and red for overdue.',
        ),
      ],
    ),
    _FaqCategory(
      title: 'Appointments',
      icon: Icons.calendar_month_outlined,
      faqs: [
        _FaqItem(
          question: 'How do I schedule an appointment?',
          answer: 'Go to the Appointments tab and tap the + button. Fill in the details including date, time, vet name, and clinic information.',
        ),
        _FaqItem(
          question: 'Will I get reminders for appointments?',
          answer: 'Paw Plan and Family Plan users receive push notifications 24 hours before an appointment. Appointment reminders are available in the Pro and Family plans only.',
        ),
        _FaqItem(
          question: 'How do I mark an appointment as completed?',
          answer: 'Swipe right on an appointment card to mark it as completed, or swipe left to cancel.',
        ),
      ],
    ),
    _FaqCategory(
      title: 'Medications',
      icon: Icons.medication_outlined,
      faqs: [
        _FaqItem(
          question: 'How do I log a medication?',
          answer: 'Go to the Medications section and tap + to add a new medication. Include the name, dosage, frequency, and start date.',
        ),
        _FaqItem(
          question: 'What do the frequency options mean?',
          answer: 'Frequency options include: Daily, Weekly, Monthly, As Needed, or Custom. Choose the option that best matches how often your pet needs the medication.',
        ),
        _FaqItem(
          question: 'How do I stop tracking a medication?',
          answer: 'Open the medication and toggle the "Active" switch. Inactive medications are moved to the bottom of the list for reference.',
        ),
      ],
    ),
    _FaqCategory(
      title: 'Subscriptions & Plans',
      icon: Icons.workspace_premium_outlined,
      faqs: [
        _FaqItem(
          question: 'What\'s included in the Free plan?',
          answer: 'Free users can add 1 pet, store up to 5 health records, and track vaccines. Document uploads and appointment reminders require a paid plan.',
        ),
        _FaqItem(
          question: 'How do I upgrade my plan?',
          answer: 'Go to Profile > Your Plan, or tap on any feature that\'s locked. Select your preferred plan and complete the purchase through your app store.',
        ),
        _FaqItem(
          question: 'How do I cancel my subscription?',
          answer: 'You can cancel anytime through your app store settings (iOS: Settings > App Store > Subscriptions, Android: Play Store > Subscriptions).',
        ),
        _FaqItem(
          question: 'Can I restore my purchases?',
          answer: 'Yes! If you reinstall the app or get a new device, go to Profile > Restore Purchases to restore your subscription.',
        ),
      ],
    ),
    _FaqCategory(
      title: 'App Settings',
      icon: Icons.settings_outlined,
      faqs: [
        _FaqItem(
          question: 'How do I change the app theme?',
          answer: 'Go to Profile > App Theme. Choose from 6 themes: Forest, Ocean, Blossom, Amber, Midnight, and Lavender. Your selection syncs across devices.',
        ),
        _FaqItem(
          question: 'Can I change weight units from kg to lbs?',
          answer: 'Yes! Go to Profile > Weight Units to toggle between kilograms (kg) and pounds (lbs).',
        ),
        _FaqItem(
          question: 'How do I enable push notifications?',
          answer: 'Go to Profile > Notifications. You can also configure notification settings directly from your device settings.',
        ),
      ],
    ),
    _FaqCategory(
      title: 'Account',
      icon: Icons.person_outline,
      faqs: [
        _FaqItem(
          question: 'How do I update my profile photo?',
          answer: 'Tap on your avatar in the Profile tab. You can choose a photo from your gallery or take a new one with your camera.',
        ),
        _FaqItem(
          question: 'How do I delete my account?',
          answer: 'Go to Profile > Delete Account. This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        _FaqItem(
          question: 'Is my data private?',
          answer: 'Yes. All your data is private and protected. Only you can see your pets\' health records. We never share your personal information with third parties.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeNotifierProvider);
    final themeData = PawThemeData.all[currentTheme]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & FAQ',
          style: TextStyle(
            fontFamily: 'DMSerifDisplay',
            fontSize: 22,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How can we help?',
                    style: TextStyle(
                      fontFamily: 'DMSerifDisplay',
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search below or browse categories',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showContactSheet(context, themeData),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Contact Support',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ..._categories.map((category) => _buildCategory(context, category, theme)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
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
                  Text(
                    'Need more help?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We typically respond within 24 hours',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.labelLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _showContactSheet(context, themeData),
                    icon: const Icon(Icons.mail_outline),
                    label: const Text('Email Us'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(BuildContext context, _FaqCategory category, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  category.icon,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: category.faqs.asMap().entries.map((entry) {
              final index = entry.key;
              final faq = entry.value;
              final isLast = index == category.faqs.length - 1;
              return _buildFaqItem(faq, theme, isLast);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFaqItem(_FaqItem faq, ThemeData theme, bool isLast) {
    final itemKey = '${faq.question}';
    final isExpanded = _expandedItems[itemKey] ?? false;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedItems[itemKey] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.vertical(
            top: isLast ? const Radius.circular(16) : Radius.zero,
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.labelLarge?.color,
                height: 1.5,
              ),
            ),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.black.withValues(alpha: 0.05),
          ),
      ],
    );
  }

  void _showContactSheet(BuildContext context, PawThemeData themeData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeData.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.email_outlined,
                size: 32,
                color: themeData.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contact Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Having issues? We\'re here to help!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openEmail(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Send Email',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }

  Future<void> _openEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@pawpass.app',
      query: 'subject=PawPass Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}

class _FaqCategory {
  final String title;
  final IconData icon;
  final List<_FaqItem> faqs;

  _FaqCategory({required this.title, required this.icon, required this.faqs});
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}
