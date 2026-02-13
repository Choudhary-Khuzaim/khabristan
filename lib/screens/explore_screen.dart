import 'package:flutter/material.dart';
import 'category_news_screen.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';
import '../widgets/shimmer_loading.dart';
import 'news_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NewsService _newsService = NewsService();
  List<NewsModel> _discoveryNews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiscoveryNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDiscoveryNews() async {
    try {
      // Fetch general news for discovery feed
      final news = await _newsService.getTopHeadlines(category: 'general');
      if (mounted) {
        setState(() {
          _discoveryNews = news;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Quietly fail or show a retry button in UI, keeping it simple for now
        debugPrint('Error loading discovery news: $e');
      }
    }
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryNewsScreen(category: query.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'World',
        'icon': Icons.public_rounded,
        'color': const Color(0xFFB4941F),
      },
      {
        'name': 'Technology',
        'icon': Icons.computer_rounded,
        'color': const Color(0xFF1E293B),
      },
      {
        'name': 'Environment',
        'icon': Icons.eco_rounded,
        'color': const Color(0xFF166534),
      },
      {
        'name': 'Health',
        'icon': Icons.health_and_safety_rounded,
        'color': const Color(0xFF991B1B),
      },
      {
        'name': 'Sports',
        'icon': Icons.sports_soccer_rounded,
        'color': const Color(0xFF1E40AF),
      },
      {
        'name': 'Business',
        'icon': Icons.business_center_rounded,
        'color': const Color(0xFF374151),
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // discovery Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _handleSearch,
                      decoration: InputDecoration(
                        hintText: 'Search news or topics',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Category Chips
            SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CategoryNewsScreen(category: cat['name']),
                            ),
                          );
                        },
                        label: Text(cat['name']),
                        avatar: Icon(
                          cat['icon'],
                          size: 16,
                          color: Colors.white,
                        ),
                        backgroundColor: cat['color'],
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Discovery Feed
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: _isLoading
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const NewsCardShimmer(),
                        childCount: 3,
                      ),
                    )
                  : _discoveryNews.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: Text(
                            'No news found',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final news = _discoveryNews[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: NewsCard(
                            news: news,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      NewsDetailScreen(news: news),
                                ),
                              );
                            },
                          ),
                        );
                      }, childCount: _discoveryNews.length),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
