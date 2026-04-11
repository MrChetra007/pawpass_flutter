import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme_data.dart';
import '../../shared/providers/theme_provider.dart';

class TermsOfServiceScreen extends ConsumerStatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  ConsumerState<TermsOfServiceScreen> createState() =>
      _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends ConsumerState<TermsOfServiceScreen> {
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
                                Icons.description_outlined,
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
                                    'Terms of Service',
                                    style: TextStyle(
                                      fontFamily: 'DMSerifDisplay',
                                      fontSize: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Last updated: April 2026',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
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
                  title: '1. Acceptance of Terms',
                  icon: Icons.check_circle_outline,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'By downloading, installing, or using the PawPass mobile application ("App") and related services ("Services"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App or Services.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '2. Description of Services',
                  icon: Icons.apps_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'PawPass provides a digital pet passport platform that allows users to:\n\n',
                    ),
                    _TextSpan(
                      '• Store and manage pet profiles and health records\n',
                    ),
                    _TextSpan('• Track vaccinations and medications\n'),
                    _TextSpan('• Schedule and manage appointments\n'),
                    _TextSpan('• Log weight and health metrics\n'),
                    _TextSpan(
                      '• Access subscription-based premium features\n\n',
                    ),
                    _TextSpan(
                      'We reserve the right to modify, suspend, or discontinue any part of the Services at any time.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '3. User Accounts',
                  icon: Icons.person_outline,
                  content: _buildRichText(theme, [
                    _TextSpan('a. Account Registration\n', isBold: true),
                    _TextSpan(
                      'To use PawPass, you must create an account. You agree to provide accurate, current, and complete information during registration.\n\n',
                    ),
                    _TextSpan('b. Account Security\n', isBold: true),
                    _TextSpan(
                      'You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. Notify us immediately of any unauthorized use.\n\n',
                    ),
                    _TextSpan('c. Account Termination\n', isBold: true),
                    _TextSpan(
                      'We may suspend or terminate your account if you violate these Terms or engage in prohibited activities.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '4. Subscription and Payments',
                  icon: Icons.credit_card_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan('a. Subscription Plans\n', isBold: true),
                    _TextSpan(
                      'PawPass offers the following subscription tiers:\n\n',
                    ),
                    _TextSpan('• Free Plan: Limited features\n'),
                    _TextSpan('• Pro Plan: \$4.99/month\n'),
                    _TextSpan('• Premium Plan: \$9.99/month\n\n'),
                    _TextSpan('b. Payment Processing\n', isBold: true),
                    _TextSpan(
                      'All payments are processed through the Apple App Store or Google Play Store. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the billing period.\n\n',
                    ),
                    _TextSpan('c. Refunds\n', isBold: true),
                    _TextSpan(
                      'Refunds are subject to the refund policies of Apple App Store and Google Play Store. We do not provide direct refunds.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '5. Acceptable Use',
                  icon: Icons.rule_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan('You agree NOT to:\n\n'),
                    _TextSpan('• Use the App for any unlawful purpose\n'),
                    _TextSpan('• Violate any laws or regulations\n'),
                    _TextSpan(
                      '• Upload false, misleading, or harmful information\n',
                    ),
                    _TextSpan('• Attempt to gain unauthorized access\n'),
                    _TextSpan(
                      '• Interfere with the proper functioning of the App\n',
                    ),
                    _TextSpan('• Reverse engineer or decompile the App\n'),
                    _TextSpan('• Share your account with others\n'),
                    _TextSpan('• Use automated tools to access the Services\n'),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '6. User Content',
                  icon: Icons.photo_library_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan('a. Ownership\n', isBold: true),
                    _TextSpan(
                      'You retain ownership of all content you submit, including pet profiles, health records, and photos ("User Content").\n\n',
                    ),
                    _TextSpan('b. License\n', isBold: true),
                    _TextSpan(
                      'By uploading User Content, you grant us a non-exclusive, worldwide, royalty-free license to use, store, and display your content solely for providing the Services.\n\n',
                    ),
                    _TextSpan('c. Responsibility\n', isBold: true),
                    _TextSpan(
                      'You represent that you own or have the necessary rights to the User Content you provide and that it does not infringe on third-party rights.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '7. Intellectual Property',
                  icon: Icons.copyright_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'The App, including its design, logos, trademarks, and all content, is owned by PawPass and protected by intellectual property laws. You may not copy, modify, or distribute our intellectual property without permission.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '8. Disclaimer of Warranties',
                  icon: Icons.warning_amber_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'THE SERVICES ARE PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND. WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.\n\n',
                      isBold: true,
                    ),
                    _TextSpan(
                      'We do not warrant that the App will be error-free, secure, or uninterrupted. Health information provided through the App is for informational purposes only and is not a substitute for professional veterinary advice.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '9. Limitation of Liability',
                  icon: Icons.shield_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'TO THE MAXIMUM EXTENT PERMITTED BY LAW, PAWPASS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF PROFITS, DATA, OR GOODWILL, ARISING FROM YOUR USE OF THE SERVICES.\n\n',
                      isBold: true,
                    ),
                    _TextSpan(
                      'Our total liability shall not exceed the amount you paid us in the twelve (12) months preceding the claim.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '10. Indemnification',
                  icon: Icons.handshake_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'You agree to indemnify, defend, and hold harmless PawPass and its affiliates from any claims, damages, losses, or expenses (including legal fees) arising from your use of the App, violation of these Terms, or infringement of any third-party rights.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '11. Third-Party Services',
                  icon: Icons.link_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'The App may contain links to third-party websites or services. We are not responsible for the content, accuracy, or opinions expressed by third parties. Your use of third-party services is subject to their respective terms.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '12. Modifications to Terms',
                  icon: Icons.edit_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'We reserve the right to modify these Terms at any time. We will notify you of material changes by posting the updated Terms in the App. Your continued use after changes constitutes acceptance of the new Terms.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '13. Governing Law',
                  icon: Icons.gavel_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'These Terms shall be governed by and construed in accordance with the laws of [JURISDICTION], without regard to its conflict of law provisions. Any disputes shall be resolved in the courts of [JURISDICTION].',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '14. Dispute Resolution',
                  icon: Icons.balance_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan('a. Informal Resolution\n', isBold: true),
                    _TextSpan(
                      'Before filing a claim, you agree to contact us and attempt to resolve the dispute informally.\n\n',
                    ),
                    _TextSpan('b. Arbitration\n', isBold: true),
                    _TextSpan(
                      'Any dispute that cannot be resolved informally shall be settled by binding arbitration in accordance with [ARBITRATION RULES].\n\n',
                    ),
                    _TextSpan('c. Class Action Waiver\n', isBold: true),
                    _TextSpan(
                      'You agree to resolve disputes individually and waive any right to participate in a class action lawsuit.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '15. Severability',
                  icon: Icons.segment_outlined,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'If any provision of these Terms is found unenforceable, the remaining provisions shall continue in full force and effect.',
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  theme,
                  title: '16. Contact Information',
                  icon: Icons.mail_outline,
                  content: _buildRichText(theme, [
                    _TextSpan(
                      'For questions about these Terms of Service, please contact us:\n\n',
                    ),
                    _TextSpan('Email: support@pawpass.app\n\n'),
                    _TextSpan(
                      'We will respond to your inquiry within 30 days.',
                      isItalic: true,
                    ),
                  ]),
                ),
                const SizedBox(height: 32),
                _buildPlaceholderSection(theme),
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
                'Agreement',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Please read these Terms of Service carefully before using PawPass. By using our services, you agree to be bound by these terms. If you do not agree, please do not use the app.',
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
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
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

  Widget _buildPlaceholderSection(ThemeData theme) {
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
            'This is a template Terms of Service. Before publishing, review and customize the following sections:\n\n',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
          ..._placeholderItem(
            theme,
            'Company Name & Details',
            'Replace "PawPass" with your actual company/legal entity name and address',
          ),
          ..._placeholderItem(
            theme,
            'Subscription Pricing',
            'Update the subscription plan names and pricing if different',
          ),
          ..._placeholderItem(
            theme,
            'Governing Law',
            'Replace [JURISDICTION] with your actual legal jurisdiction',
          ),
          ..._placeholderItem(
            theme,
            'Dispute Resolution',
            'Replace [ARBITRATION RULES] with your actual arbitration provider',
          ),
          ..._placeholderItem(
            theme,
            'Contact Information',
            'Replace "support@pawpass.app" with your actual support email',
          ),
          ..._placeholderItem(
            theme,
            'Arbitration Provider',
            'Specify your preferred arbitration service (e.g., AAA, JAMS)',
          ),
          ..._placeholderItem(
            theme,
            'GDPR/CCPA Compliance',
            'Add region-specific terms if serving EU or California users',
          ),
          ..._placeholderItem(
            theme,
            'DMCA Policy',
            'Add Digital Millennium Copyright Act takedown procedures',
          ),
          const SizedBox(height: 12),
          Text(
            'Consult with a legal professional to ensure compliance with applicable laws.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.textTheme.labelLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _placeholderItem(
    ThemeData theme,
    String title,
    String description,
  ) {
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
                    color: theme.textTheme.labelLarge?.color?.withValues(
                      alpha: 0.7,
                    ),
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
