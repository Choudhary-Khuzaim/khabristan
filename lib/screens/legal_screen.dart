import 'package:flutter/material.dart';
import '../widgets/glass_background.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
          title: const Text('Legal'),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.secondary,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Theme.of(context).colorScheme.secondary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Terms & Conditions'),
              Tab(text: 'Privacy Policy'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Terms & Conditions Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms & Conditions',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Khabaristan!\n\n'
                    '1. Acceptance of Terms\n'
                    'By accessing or using our app, you agree to be bound by these terms.\n\n'
                    '2. Use of Content\n'
                    'The news content provided in this app is aggregated from various public RSS feeds. We do not claim ownership of the original content.\n\n'
                    '3. User Conduct\n'
                    'You agree not to use the app for any unlawful purpose or in any way that interrupts, damages, or impairs the service.\n\n'
                    '4. Disclaimer\n'
                    'The news provided is for general information purposes only. We do not guarantee the accuracy, completeness, or usefulness of this information.\n\n'
                    '5. Changes to Terms\n'
                    'We reserve the right to modify these terms at any time. Your continued use of the app constitutes acceptance of the new terms.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 15),
                  ),
                ],
              ),
            ),
            
            // Privacy Policy Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your privacy is important to us.\n\n'
                    '1. Information We Collect\n'
                    'We may collect basic usage data to improve your experience. We do not collect personally identifiable information without your consent.\n\n'
                    '2. How We Use Your Information\n'
                    'The data we collect is used to personalize your news feed, remember your preferences (like dark mode and saved articles), and improve the app\'s performance.\n\n'
                    '3. Third-Party Services\n'
                    'We use third-party RSS feeds to deliver news. These third-party services may have their own privacy policies.\n\n'
                    '4. Data Security\n'
                    'We implement reasonable security measures to protect your data, though no method of transmission over the Internet is 100% secure.\n\n'
                    '5. Contact Us\n'
                    'If you have any questions about this Privacy Policy, please contact us.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
