import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme_data.dart';
import '../../shared/providers/theme_provider.dart';

class PrivacyPolicyScreen extends ConsumerStatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  ConsumerState<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends ConsumerState<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showBackToTop) {
      setState(() => _showBackToTop = true);
    } else if (_scrollController.offset <= 300 && _showBackToTop) {
      setState(() => _showBackToTop = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTheme = ref.watch(themeNotifierProvider);
    final themeData = PawThemeData.all[currentTheme]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.privacy_tip_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontFamily: 'DMSerifDisplay',
                                      fontSize: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Last updated: April 2026',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildIntroCard(theme),
                const SizedBox(height: 20),
                _buildSection(
                  theme,
                  title: '1. Information We Collect',
                  icon: Icons.folder_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'a. Personal Information\n',
                        isBold: true,
                      ),
                      _TextSpan(
                        'We collect information you provide directly to us, including:\n',
                      ),
                      _TextSpan('• Name and email address when you create an account\n'),
                      _TextSpan('• Profile information and profile photo\n'),
                      _TextSpan('• Information about your pets (name, species, breed, health records)\n'),
                      _TextSpan('• Payment information for subscription management (processed securely by Apple/Google)\n\n'),
                      _TextSpan(
                        'b. Automatically Collected Information\n',
                        isBold: true,
                      ),
                      _TextSpan(
                        'When you use PawPass, we may automatically collect:\n',
                      ),
                      _TextSpan('• Device type and operating system\n'),
                      _TextSpan('• Usage data and app interactions\n'),
                      _TextSpan('• Diagnostic and crash reports\n'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '2. How We Use Your Information',
                  icon: Icons.analytics_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'We use the information we collect to:\n\n',
                      ),
                      _TextSpan('• Provide, maintain, and improve our services\n'),
                      _TextSpan('• Process transactions and send related information\n'),
                      _TextSpan('• Send you technical notices and support messages\n'),
                      _TextSpan('• Respond to your comments and questions\n'),
                      _TextSpan('• Monitor and analyze trends and usage\n'),
                      _TextSpan('• Personalize and improve your experience\n'),
                      _TextSpan('• Comply with legal obligations\n'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '3. Information Sharing',
                  icon: Icons.share_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'We do not sell, trade, or otherwise transfer your personal information to third parties except in the following circumstances:\n\n',
                      ),
                      _TextSpan('• With your explicit consent\n'),
                      _TextSpan('• To comply with legal requirements\n'),
                      _TextSpan('• To protect our rights and prevent fraud\n'),
                      _TextSpan('• With service providers who assist in our operations (bound by confidentiality)\n'),
                      _TextSpan('• In connection with a business transfer (acquisition or merger)\n'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '4. Data Security',
                  icon: Icons.security_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'We implement appropriate technical and organizational measures to protect your personal information, including:\n\n',
                      ),
                      _TextSpan('• Encryption of data in transit and at rest\n'),
                      _TextSpan('• Secure authentication via Supabase\n'),
                      _TextSpan('• Regular security assessments\n'),
                      _TextSpan('• Access controls and employee training\n\n'),
                      _TextSpan(
                        'While we strive to protect your information, no method of transmission over the Internet is 100% secure.',
                        isItalic: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '5. Data Retention',
                  icon: Icons.storage_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'We retain your personal information for as long as necessary to:\n\n',
                      ),
                      _TextSpan('• Provide you with our services\n'),
                      _TextSpan('• Comply with legal obligations\n'),
                      _TextSpan('• Resolve disputes and enforce agreements\n\n'),
                      _TextSpan(
                        'When you delete your account, we will delete or anonymize your personal information within a reasonable timeframe. Some information may be retained for longer if required by law.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '6. Your Rights',
                  icon: Icons.gavel_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'Depending on your location, you may have the following rights:\n\n',
                      ),
                      _TextSpan('• Right to access your personal information\n'),
                      _TextSpan('• Right to correct inaccurate data\n'),
                      _TextSpan('• Right to delete your data ("Right to be Forgotten")\n'),
                      _TextSpan('• Right to data portability\n'),
                      _TextSpan('• Right to object to processing\n'),
                      _TextSpan('• Right to withdraw consent\n\n'),
                      _TextSpan(
                        'To exercise these rights, please contact us at support@pawpass.app or delete your account through the app settings.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '7. Children\'s Privacy',
                  icon: Icons.child_care_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'PawPass is not intended for use by children under the age of 13 (or equivalent minimum age in your jurisdiction). We do not knowingly collect personal information from children. If you believe a child has provided us with personal data, please contact us immediately.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '8. Third-Party Services',
                  icon: Icons.link_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'Our services may contain links to third-party websites or services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies before providing any personal information.\n\n',
                      ),
                      _TextSpan(
                        'We use the following third-party services:\n\n',
                        isBold: true,
                      ),
                      _TextSpan('• Supabase - Database and authentication\n'),
                      _TextSpan('• Apple App Store / Google Play - Payment processing\n'),
                      _TextSpan('• Flutter - App framework\n'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '9. International Data Transfers',
                  icon: Icons.public_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place for such transfers, including standard contractual clauses where required.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '10. Changes to This Policy',
                  icon: Icons.update_outlined,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'We may update this Privacy Policy from time to time. We will notify you of any material changes by posting the new policy in the app and updating the "Last updated" date. We encourage you to review this policy periodically.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '11. Contact Us',
                  icon: Icons.mail_outline,
                  content: _buildRichText(
                    theme,
                    [
                      _TextSpan(
                        'If you have any questions about this Privacy Policy or our data practices, please contact us:\n\n',
                      ),
                      _TextSpan('Email: support@pawpass.app\n\n'),
                      _TextSpan(
                        'We will respond to your inquiry within 30 days.',
                        isItalic: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildPlaceholderSection(theme, themeData),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: _showBackToTop
          ? FloatingActionButton.small(
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ),
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.arrow_upward, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildIntroCard(ThemeData theme) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Introduction',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'PawPass ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and related services.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
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
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [content],
        ),
      ),
    );
  }

  Widget _buildRichText(ThemeData theme, List<_TextSpan> spans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spans.map((span) {
        return Text(
          span.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
            color: theme.textTheme.labelLarge?.color,
            fontWeight: span.isBold ? FontWeight.w600 : null,
            fontStyle: span.isItalic ? FontStyle.italic : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlaceholderSection(ThemeData theme, PawThemeData themeData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PawThemeData.alertAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PawThemeData.alertAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_outlined,
                color: PawThemeData.alertAmber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Customization Needed',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: PawThemeData.alertAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This is a template privacy policy. Before publishing, review and customize the following sections to ensure compliance with:\n\n',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
          ..._placeholderItem(
            theme,
            'Company/Developer Information',
            'Replace "PawPass" and "support@pawpass.app" with your actual company details',
          ),
          ..._placeholderItem(
            theme,
            'Third-Party Services',
            'Add all third-party services you actually use (analytics, crash reporting, etc.)',
          ),
          ..._placeholderItem(
            theme,
            'Data Retention Periods',
            'Specify exact retention periods based on your data practices',
          ),
          ..._placeholderItem(
            theme,
            'Jurisdiction',
            'Specify the governing law and jurisdiction for your legal compliance',
          ),
          ..._placeholderItem(
            theme,
            'Cookie Policy (if applicable)',
            'Add if you use any tracking or cookies',
          ),
          ..._placeholderItem(
            theme,
            'GDPR/CCPA Specifics',
            'Add region-specific disclosures if you serve EU or California users',
          ),
          const SizedBox(height: 12),
          Text(
            'Consider consulting with a legal professional to ensure full compliance.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _placeholderItem(ThemeData theme, String title, String description) {
    return [
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_box_outline_blank,
            size: 16,
            color: theme.textTheme.labelLarge?.color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.labelLarge?.color,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }
}

class _TextSpan {
  final String text;
  final bool isBold;
  final bool isItalic;

  _TextSpan(this.text, {this.isBold = false, this.isItalic = false});
}
