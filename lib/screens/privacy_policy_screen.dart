import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
            backgroundColor: theme.scaffoldBackgroundColor,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(theme, 'COMMITMENT TO PRIVACY'),
                _buildContentCard(
                  theme,
                  'At KhabarIsTan, we believe that your data belongs to you. Our architecture is designed with a "Local First" approach, ensuring that your reading habits and personal information remain private.',
                ),
                const SizedBox(height: 32),

                _buildSectionHeader(theme, 'DATA COLLECTION'),
                _buildContentCard(
                  theme,
                  '• Local Storage: All your bookmarks, published news (local history), and preferences are stored exclusively on your device using encrypted local storage.\n\n• Servers: We do not maintain user accounts on our central servers. When you read news, your IP address is used only to fetch the headlines and is not logged against any personal profile.\n\n• Third-Party Services: We use trusted news aggregators to provide headlines. These providers do not receive any identifying information from our app.',
                ),
                const SizedBox(height: 32),

                _buildSectionHeader(theme, 'USER RIGHTS'),
                _buildContentCard(
                  theme,
                  'You have full control over your data. Since it is stored locally, you can clear all your information by resetting the application or clearing the cache in your system settings. We do not have any "backdoor" access to your saved articles.',
                ),
                const SizedBox(height: 48),

                Center(
                  child: Text(
                    'Last Updated: January 16, 2026',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildContentCard(ThemeData theme, String content) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 15,
          height: 1.8,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
