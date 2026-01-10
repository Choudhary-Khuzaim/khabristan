import 'package:flutter/material.dart';

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
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
          ),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: themeService.isDarkMode,
                  onChanged: (value) {
                    themeService.toggleTheme(value);
                  },
                ),
              ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Region & Language'),
            subtitle: const Text('United States (English)'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: const Text('Select Region'),
                  children: [
                    _buildRegionOption(context, 'United States (English)', 'us'),
                    _buildRegionOption(context, 'United Kingdom (English)', 'gb'),
                    _buildRegionOption(context, 'Pakistan (English/Urdu)', 'pk'),
                    _buildRegionOption(context, 'India (English)', 'in'),
                    _buildRegionOption(context, 'Canada (English)', 'ca'),
                    _buildRegionOption(context, 'Australia (English)', 'au'),
                    _buildRegionOption(context, 'United Arab Emirates (English)', 'ae'),
                    _buildRegionOption(context, 'Saudi Arabia (English)', 'sa'),
                    _buildRegionOption(context, 'Singapore (English)', 'sg'),
                    _buildRegionOption(context, 'South Africa (English)', 'za'),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About App'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'Privacy Policy for KhabarIsTan\n\n'
                      '1. Introduction\n'
                      'Welcome to KhabarIsTan. We respect your privacy and are committed to protecting your personal data.\n\n'
                      '2. Data Collection\n'
                      'We do not collect any personal data. The app fetches news from public APIs and stores your bookmarks locally on your device.\n\n'
                      '3. Third-Party Services\n'
                      'We use third-party services like NewsAPI.org for content. Please review their privacy policies.\n\n'
                      '4. Changes\n'
                      'We may update this policy from time to time. Continued use of the app implies acceptance.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          ],
          ),
        );
      },
    );
  }

  Widget _buildRegionOption(BuildContext context, String name, String code) {
    return SimpleDialogOption(
      onPressed: () async {
        Navigator.pop(context);
        // Using ThemeService as a proxy or direct PrefsService if available
        // Ideally we should use PreferencesService directly, but let's stick to the pattern.
        // Actually, let's use PreferencesService directly here.
        final preferencesService = PreferencesService();
        await preferencesService.setRegion(code);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Region set to $name. Restart app to apply changes fully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(name),
      ),
    );
  }
}
