import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'category_news_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'General',
        'icon': Icons.public_rounded,
        'gradient': [const Color(0xFF89f7fe), const Color(0xFF66a6ff)],
      },
      {
        'name': 'Business',
        'icon': Icons.business_rounded,
        'gradient': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      },
      {
        'name': 'Entertainment',
        'icon': Icons.movie_creation_rounded,
        'gradient': [const Color(0xFFff9a9e), const Color(0xFFfecfef)],
      },
      {
        'name': 'Health',
        'icon': Icons.health_and_safety_rounded,
        'gradient': [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      },
      {
        'name': 'Science',
        'icon': Icons.science_rounded,
        'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      },
      {
        'name': 'Sports',
        'icon': Icons.sports_soccer_rounded,
        'gradient': [const Color(0xFFfa709a), const Color(0xFFfee140)],
      },
      {
        'name': 'Technology',
        'icon': Icons.computer_rounded,
        'gradient': [const Color(0xFF30cfd0), const Color(0xFF330867)],
      },
      {
        'name': 'Automotive',
        'icon': Icons.directions_car_rounded,
        'gradient': [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)],
      },
      {
        'name': 'Food',
        'icon': Icons.restaurant_rounded,
        'gradient': [const Color(0xFFffecd2), const Color(0xFFfcb69f)],
      },
      {
        'name': 'Travel',
        'icon': Icons.flight_takeoff_rounded,
        'gradient': [const Color(0xFFa1c4fd), const Color(0xFFc2e9fb)],
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore news by topic',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Find topics...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: AnimationLimiter(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      columnCount: 2,
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryNewsScreen(
                                    category: category['name'] as String,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: category['gradient'] as List<Color>,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: (category['gradient'] as List<Color>)[0]
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -10,
                                    bottom: -10,
                                    child: Icon(
                                      category['icon'] as IconData,
                                      size: 80,
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            category['icon'] as IconData,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        Text(
                                          category['name'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}
