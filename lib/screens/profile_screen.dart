import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'edit_profile_screen.dart';
import 'my_news_screen.dart';
import '../services/preferences_service.dart';
import '../services/theme_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Khuzaim';
  String? _bio;
  String? _phone;
  String? _location;
  bool _notificationsEnabled = true;
  final _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = PreferencesService();
    final username = await prefs.getUsername();
    final bio = await prefs.getBio();
    final phone = await prefs.getPhone();
    final location = await prefs.getLocation();
    final notifications = await prefs.getNotificationsEnabled();

    if (mounted) {
      setState(() {
        if (username != null) _username = username;
        _bio = bio;
        _phone = phone;
        _location = location;
        _notificationsEnabled = notifications;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280, // Increased height for extra details
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _username,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (_bio != null && _bio!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _bio!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (_location != null && _location!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _location!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        if (_phone != null && _phone!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _phone!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildListDelegate(
                      AnimationConfiguration.toStaggeredList(
                        duration: const Duration(milliseconds: 375),
                        childAnimationBuilder: (widget) => SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(
                            child: widget,
                            ),
                        ),
                        children: [
                          _buildSectionHeader(context, 'Account'),
                          _buildProfileItem(context, Icons.person_outline, 'Edit Profile', onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                            );

                            if (result != null && result is Map<String, String>) {
                              setState(() {
                                _username = result['username'] ?? _username;
                                _bio = result['bio'];
                                _phone = result['phone'];
                                _location = result['location'];
                              });
                              _loadProfileData();
                            } else if (result == true) {
                              _loadProfileData();
                            }
                          }),
                          
                          // My News
                          _buildProfileItem(context, Icons.article_outlined, 'My News', onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyNewsScreen()),
                            );
                          }),

                          // Notifications with a switch
                          _buildSwitchProfileItem(
                            context, 
                            Icons.notifications_outlined, 
                            'Notifications', 
                            _notificationsEnabled, 
                            (val) async {
                              setState(() {
                                _notificationsEnabled = val;
                              });
                              await PreferencesService().setNotificationsEnabled(val);
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          _buildSectionHeader(context, 'Preferences'),
                          
                          // Region & Language
                          _buildProfileItem(context, Icons.language, 'Region & Language', subtitle: 'United States (English)', onTap: () {
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
                          }),

                          // Dark Mode
                          _buildSwitchProfileItem(
                            context,
                            Icons.dark_mode_outlined,
                            'Dark Mode',
                            _themeService.isDarkMode,
                            (value) {
                              _themeService.toggleTheme(value);
                            },
                          ),

                          const SizedBox(height: 24),
                          _buildSectionHeader(context, 'Support'),
                          
                           // Privacy Policy
                          _buildProfileItem(context, Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () {
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
                          }),
                          
                          // About App
                          _buildProfileItem(context, Icons.info_outline_rounded, 'About App', subtitle: 'Version 1.0.0', onTap: () {}),

                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () async {
                              await PreferencesService().clearSession();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Logout'),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, {String? subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSwitchProfileItem(BuildContext context, IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildRegionOption(BuildContext context, String name, String code) {
    return SimpleDialogOption(
      onPressed: () async {
        Navigator.pop(context);
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
