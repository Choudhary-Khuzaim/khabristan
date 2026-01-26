import 'package:flutter/material.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';

import '../services/theme_service.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return AnimatedBuilder(
      animation: themeService,
      builder: (context, child) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Settings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('APPEARANCE'),
                    _buildSettingItem(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      trailing: Switch.adaptive(
                        value: themeService.isDarkMode,
                        onChanged: (v) => themeService.toggleTheme(v),
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('PREFERENCES'),
                    _buildSettingItem(
                      icon: Icons.notifications_rounded,
                      title: 'Real-time Notifications',
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (v) {},
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.public_rounded,
                      title: 'Content Region',
                      subtitle: 'United States (Default)',
                      onTap: () => _showRegionPicker(context),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('ABOUT'),
                    _buildSettingItem(
                      icon: Icons.info_rounded,
                      title: 'About KhabarIsTan',
                      subtitle: 'Our Mission & Version info',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutAppScreen(),
                        ),
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.policy_rounded,
                      title: 'Privacy Policy',
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded, size: 20)
              : null),
    );
  }

  void _showRegionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Content Region',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildRegionOption(context, 'United States', 'us'),
                  _buildRegionOption(context, 'United Kingdom', 'gb'),
                  _buildRegionOption(context, 'Pakistan', 'pk'),
                  _buildRegionOption(context, 'India', 'in'),
                  _buildRegionOption(context, 'Canada', 'ca'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionOption(BuildContext context, String name, String code) {
    return ListTile(
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.circle_outlined, size: 18),
      onTap: () async {
        Navigator.pop(context);
        final prefs = PreferencesService();
        await prefs.setRegion(code);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Region updated to $name'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }
}
