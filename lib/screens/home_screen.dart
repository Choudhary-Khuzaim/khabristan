import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/date_helper.dart';

import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';
import '../widgets/featured_news_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';
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
  List<NewsModel> _trendingNewsList = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedCategory = 'general';
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  int _featuredPageIndex = 0;
  late PageController _featuredPageController;

  DateTime? _lastUpdated;
  Timer? _autoRefreshTimer;

  // Live pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Category list
  static const List<Map<String, dynamic>> _categories = [
    {'key': 'general', 'label': 'General', 'icon': Icons.public_rounded},
    {'key': 'business', 'label': 'Business', 'icon': Icons.trending_up_rounded},
    {'key': 'technology', 'label': 'Tech', 'icon': Icons.memory_rounded},
    {'key': 'sports', 'label': 'Sports', 'icon': Icons.sports_soccer_rounded},
    {'key': 'science', 'label': 'Science', 'icon': Icons.science_rounded},
    {'key': 'health', 'label': 'Health', 'icon': Icons.favorite_rounded},
    {'key': 'entertainment', 'label': 'Entertainment', 'icon': Icons.movie_rounded},
  ];



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

    _featuredPageController = PageController(viewportFraction: 0.88);

    _loadNewsWithCache();

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

  /// Cache-first: show cached data instantly, then refresh in background
  Future<void> _loadNewsWithCache() async {
    final cached = _newsService.getCachedGeneralNews();
    
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _newsList = cached;
        _filteredNewsList = cached;
        _featuredNewsList = cached.take(5).toList();
        _trendingNewsList = cached.take(8).toList();
        _lastUpdated = _newsService.lastFetchTime;
        _isLoading = false;
      });
      // Refresh in background
      _silentRefresh();
    } else {
      // No cache — must fetch with loading indicator
      await _loadNews();
    }
  }

  Future<void> _silentRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final news = await _newsService.getTopHeadlines(
        category: _selectedCategory, 
        forceRefresh: true
      );

      if (mounted) {
        setState(() {
          _newsList = news;
          _filteredNewsList = news;
          _featuredNewsList = news.take(5).toList();
          _trendingNewsList = news.take(8).toList();
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
    _featuredPageController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final news = await _newsService.getTopHeadlines(
        category: _selectedCategory
      );

      setState(() {
        _newsList = news;
        _filteredNewsList = news;
        _featuredNewsList = news.take(5).toList();
        _trendingNewsList = news.take(8).toList();
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

  void _onCategoryChanged(String category) {
    if (_selectedCategory == category) return;
    
    setState(() {
      _selectedCategory = category;
    });

    // Try showing cached category data instantly
    final cached = _newsService.getCachedCategoryNews(category);
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _newsList = cached;
        _filteredNewsList = cached;
        _featuredNewsList = cached.take(5).toList();
        _trendingNewsList = cached.take(8).toList();
        _isLoading = false;
      });
      // Refresh in background
      _silentRefresh();
    } else {
      _loadNews();
    }
  }


  void _navigateToDetail(NewsModel news, String heroTag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news, heroTag: heroTag)),
    );
  }

  String _getTimeAgo(DateTime? dateTime) {
    return DateHelper.timeAgoFromDateTime(dateTime);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
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
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
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
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFE94560), // Vibrant coral-red
                                          Color(0xFFFF8A65), // Orange accent
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
                                  color: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                    ),
                                  ],
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

                      // Greeting + LIVE badge row
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Row(
                            children: [
                              // Greeting text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getGreeting(),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Stay informed, stay ahead',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                            color: Colors.redAccent,
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
                              const SizedBox(width: 8),
                              // Refresh + Last updated
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

                      // Category Filter Chips
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final isSelected = _selectedCategory == cat['key'];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  child: InkWell(
                                    onTap: () => _onCategoryChanged(cat['key']),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: isSelected
                                            ? const LinearGradient(
                                                colors: [Color(0xFFE94560), Color(0xFFFF8A65)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: isSelected
                                            ? null
                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(20),
                                        border: isSelected
                                            ? null
                                            : Border.all(
                                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                                              ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            cat['icon'] as IconData,
                                            size: 15,
                                            color: isSelected
                                                ? Colors.white
                                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            cat['label'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
                              controller: _featuredPageController,
                              padEnds: false,
                              itemCount: _featuredNewsList.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _featuredPageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final featured = _featuredNewsList[index];
                                final tag = 'home_featured_${featured.url ?? featured.title}';
                                return FeaturedNewsCard(
                                  news: featured,
                                  heroPrefix: 'home_featured',
                                  onTap: () => _navigateToDetail(featured, tag),
                                );
                              },
                            ),
                          ),
                        ),
                        // Page indicator dots
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  _featuredNewsList.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: _featuredPageIndex == index ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: _featuredPageIndex == index
                                          ? const LinearGradient(
                                              colors: [Color(0xFFE94560), Color(0xFFFF8A65)],
                                            )
                                          : null,
                                      color: _featuredPageIndex == index
                                          ? null
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Trending Now horizontal section
                      if (_trendingNewsList.isNotEmpty && !_isLoading) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  color: Color(0xFFE94560),
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Trending Now',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 130,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _trendingNewsList.length.clamp(0, 8),
                              itemBuilder: (context, index) {
                                final news = _trendingNewsList[index];
                                return GlassContainer(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(12),
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _navigateToDetail(
                                    news,
                                    'trending_${news.url ?? news.title}_${news.publishedAt ?? 'now'}',
                                  ),
                                  child: SizedBox(
                                    width: 200,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Source + index badge
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFFE94560), Color(0xFFFF8A65)],
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '#${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                news.source ?? 'News',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        // Title
                                        Expanded(
                                          child: Text(
                                            news.title ?? '',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              height: 1.3,
                                            ),
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Time ago
                                        Text(
                                          DateHelper.timeAgo(news.publishedAt),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],


                      // Recent News Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                              const Spacer(),
                              if (_lastUpdated != null)
                                Text(
                                  'Updated ${_getTimeAgo(_lastUpdated)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.4),
                                    fontWeight: FontWeight.w500,
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
        extendBody: true,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(30),
            blur: 20,
            opacity: 0.2,
            child: SafeArea(
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
    final primaryColor = Theme.of(context).colorScheme.secondary; // Coral-red

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? primaryColor : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
