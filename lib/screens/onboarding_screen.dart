import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/preferences_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PreferencesService _prefs = PreferencesService();
  String _selectedRegion = 'us';

  final List<Map<String, String>> _regions = [
    {'code': 'us', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': 'gb', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'pk', 'name': 'Pakistan', 'flag': '🇵🇰'},
    {'code': 'in', 'name': 'India', 'flag': '🇮🇳'},
    {'code': 'ca', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': 'au', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': 'ae', 'name': 'UAE', 'flag': '🇦🇪'},
    {'code': 'sa', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'code': 'sg', 'name': 'Singapore', 'flag': '🇸🇬'},
    {'code': 'za', 'name': 'South Africa', 'flag': '🇿🇦'},
  ];

  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _prefs.setRegion(_selectedRegion);
      await _prefs.setOnboardingComplete();
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      // Continue navigation even if save fails
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Select your Region',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get news relevant to your location',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: AnimationLimiter(
                  child: ListView.builder(
                    itemCount: _regions.length,
                    itemBuilder: (context, index) {
                      final region = _regions[index];
                      final isSelected = _selectedRegion == region['code'];

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedRegion = region['code']!;
                                  });
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.transparent
                                          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        region['flag']!,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        region['name']!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _completeOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
