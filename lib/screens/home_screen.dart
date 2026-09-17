import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';
import '../widgets/featured_news_card.dart';
import '../widgets/shimmer_loading.dart';
import 'news_detail_screen.dart';

import 'explore_screen.dart';
import 'saved_news_screen.dart';
import 'all_news_screen.dart';
import 'legal_screen.dart';
import '../services/theme_service.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  List<NewsModel> _newsList = [];
  List<NewsModel> _featuredNewsList = [];
  List<NewsModel> _filteredNewsList = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final String _selectedCategory = 'general';
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

  DateTime? _lastUpdated;
  Timer? _autoRefreshTimer;

  // Live pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;



  @override
  void initState() {
    super.initState();

    // Setup pulse animation for LIVE indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadNews();

    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Auto-refresh every 5 minutes for real-time news
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_currentIndex == 0) {
        _silentRefresh();
      }
    });
  }

  Future<void> _silentRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final results = await Future.wait([
        _newsService.getTopHeadlines(category: _selectedCategory),
        if (_selectedCategory == 'general')
          _newsService.getFeaturedNews(limit: 5)
        else
          Future.value(<NewsModel>[]),
      ]);

      final news = results[0];
      final featured = results.length > 1 ? results[1] : <NewsModel>[];

      if (mounted) {
        setState(() {
          _newsList = news;
          _filteredNewsList = news;
          _featuredNewsList = featured;
          _lastUpdated = DateTime.now();
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }



  @override
  void dispose() {
    _scrollController.dispose();
    _autoRefreshTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch category news and featured news in parallel
      final results = await Future.wait([
        _newsService.getTopHeadlines(category: _selectedCategory),
        if (_selectedCategory == 'general')
          _newsService.getFeaturedNews(limit: 5)
        else
          Future.value(<NewsModel>[]),
      ]);

      final news = results[0];
      final featured = results.length > 1 ? results[1] : <NewsModel>[];

      setState(() {
        _newsList = news;
        _filteredNewsList = news;
        _featuredNewsList = featured;
        _lastUpdated = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading news: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }





  void _navigateToDetail(NewsModel news, String heroTag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news, heroTag: heroTag)),
    );
  }

  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Home Tab Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadNews,
              color: Theme.of(context).colorScheme.primary,
              child: AnimationLimiter(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Premium Top Bar
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // App Logo & Name
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context).colorScheme.primary,
                                        Theme.of(context).colorScheme.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.public_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Khabaristan',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Settings Capsule
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Dark Mode Toggle
                                  AnimatedBuilder(
                                    animation: ThemeService(),
                                    builder: (context, _) {
                                      final isDark = ThemeService().isDarkMode;
                                      return InkWell(
                                        onTap: () {
                                          ThemeService().toggleTheme(!isDark);
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: isDark ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.dark_mode_rounded,
                                            size: 18,
                                            color: isDark ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      );
                                    }
                                  ),
                                  const SizedBox(width: 4),
                                  // Legal Screen Button
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LegalScreen()),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.transparent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.shield_rounded,
                                        size: 18,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // LIVE Real-Time Badge + Last Updated
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // LIVE badge
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red.withOpacity(
                                            _pulseAnimation.value,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withOpacity(
                                                _pulseAnimation.value * 0.5,
                                              ),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            // Last updated text
                            if (_lastUpdated != null)
                              Text(
                                'Updated ${_getTimeAgo(_lastUpdated)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const Spacer(),
                            // Manual refresh button
                            if (_isRefreshing)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              InkWell(
                                onTap: _silentRefresh,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),



                    // Featured News Carousel
                    if (_featuredNewsList.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Top Stories',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'BREAKING',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllNewsScreen(
                                        title: 'Top Stories',
                                        newsList: _newsList,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 220,
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.88),
                            padEnds: false,
                            itemCount: _featuredNewsList.length,
                            itemBuilder: (context, index) {
                              return FeaturedNewsCard(
                                news: _featuredNewsList[index],
                                heroPrefix: 'home_featured',
                                onTap: () =>
                                    _navigateToDetail(_featuredNewsList[index], 'home_featured_${_featuredNewsList[index].url ?? _featuredNewsList[index].title}'),
                              );
                            },
                          ),
                        ),
                      ),
                    ],



                    // Recent News Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              'Recent News',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(width: 8),
                            if (_filteredNewsList.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_filteredNewsList.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // News List
                    if (_isLoading)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const NewsCardShimmer(),
                          childCount: 5,
                        ),
                      )
                    else if (_filteredNewsList.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No news found',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: NewsCard(
                                  news: _filteredNewsList[index],
                                  heroPrefix: 'home_list',
                                  onTap: () =>
                                      _navigateToDetail(_filteredNewsList[index], 'home_list_${_filteredNewsList[index].url ?? _filteredNewsList[index].title}_${_filteredNewsList[index].publishedAt ?? 'now'}'),
                                ),
                              ),
                            ),
                          );
                        }, childCount: _filteredNewsList.length),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ),

          // Explore Tab
          const ExploreScreen(),

          // Saved Tab
          const SavedNewsScreen(),


        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          height: 80,
          elevation: 0,
          color: Theme.of(context).cardTheme.color,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                0,
                Icons.grid_view_rounded,
                Icons.grid_view_rounded,
                'Home',
              ),
              _buildNavItem(
                1,
                Icons.explore_rounded,
                Icons.explore_rounded,
                'Explore',
              ),

              _buildNavItem(
                2,
                Icons.bookmark_rounded,
                Icons.bookmark_rounded,
                'Saved',
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
            _currentIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4), // Reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 2), // Reduced spacing
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11, // Slightly smaller text
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
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
