import 'package:flutter/material.dart';
import 'privacy_policy_screen.dart';
import 'about_screen.dart';

import '../services/theme_service.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();
  String _currentRegion = 'us';
  bool _notificationsEnabled = true;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final region = await _prefs.getRegion();
    final notifications = await _prefs.getNotificationsEnabled();
    if (mounted) {
      setState(() {
        _currentRegion = region;
        _notificationsEnabled = notifications;
        _isInit = true;
      });
    }
  }

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
              if (!_isInit)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
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
                          value: _notificationsEnabled,
                          onChanged: (v) async {
                            await _prefs.setNotificationsEnabled(v);
                            setState(() => _notificationsEnabled = v);
                          },
                          activeThumbColor: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      _buildSettingItem(
                        icon: Icons.public_rounded,
                        title: 'Content Region',
                        subtitle: _prefs.getRegionName(_currentRegion),
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
          color: Colors.grey.withOpacity(0.1),
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
                   _buildRegionOption(context, 'Australia', 'au'),
                   _buildRegionOption(context, 'UAE', 'ae'),
                   _buildRegionOption(context, 'Saudi Arabia', 'sa'),
                   _buildRegionOption(context, 'Singapore', 'sg'),
                   _buildRegionOption(context, 'South Africa', 'za'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionOption(BuildContext context, String name, String code) {
    final bool isSelected = _currentRegion == code;
    return ListTile(
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
      trailing: Icon(
        isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
        size: 18,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      onTap: () async {
        Navigator.pop(context);
        await _prefs.setRegion(code);
        setState(() {
          _currentRegion = code;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Region updated to $name'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
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
