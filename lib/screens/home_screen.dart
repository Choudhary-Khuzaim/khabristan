import 'dart:async';
import 'package:flutter/material.dart';
import '../services/preferences_service.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';
import '../widgets/featured_news_card.dart';
import '../widgets/shimmer_loading.dart';
import 'news_detail_screen.dart';
import 'profile_screen.dart';
import 'explore_screen.dart';
import 'saved_news_screen.dart';
import 'all_news_screen.dart';
import 'add_news_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchController = TextEditingController();
  List<NewsModel> _newsList = [];
  List<NewsModel> _featuredNewsList = [];
  List<NewsModel> _filteredNewsList = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSearching = false;
  String _selectedCategory = 'general';
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  String _userName = 'Khuzaim';
  DateTime? _lastUpdated;
  Timer? _autoRefreshTimer;

  // Live pulse animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'general', 'icon': Icons.public},
    {'name': 'business', 'icon': Icons.business},
    {'name': 'entertainment', 'icon': Icons.movie},
    {'name': 'health', 'icon': Icons.health_and_safety},
    {'name': 'science', 'icon': Icons.science},
    {'name': 'sports', 'icon': Icons.sports_soccer},
    {'name': 'technology', 'icon': Icons.computer},
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

    _loadNews();
    _loadUserName();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Auto-refresh every 5 minutes for real-time news
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_currentIndex == 0 && !_isSearching) {
        _silentRefresh();
      }
    });
  }

  Future<void> _silentRefresh() async {
    if (_isRefreshing || _isSearching) return;

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

  Future<void> _loadUserName() async {
    final name = await PreferencesService().getUsername();
    if (name != null && mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _isSearching = false;
    });
    _loadNews();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _filterNews(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredNewsList = _newsList;
      } else {
        _filteredNewsList = _newsList.where((news) {
          final title = news.title?.toLowerCase() ?? '';
          final description = news.description?.toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return title.contains(searchQuery) ||
              description.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _handleGlobalSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final results = await _newsService.searchNews(query: query.trim());
      setState(() {
        _filteredNewsList = results;
        _featuredNewsList = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search error: ${e.toString()}'),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back,',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  _userName, // Dynamic User Name
                                  style: Theme.of(context).textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.1),
                                child: const Icon(Icons.person_rounded),
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

                    // Premium Search Bar
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterNews,
                          onSubmitted: _handleGlobalSearch,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Search for global headlines...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      _filterNews('');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Theme.of(context).cardTheme.color,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Featured News Carousel
                    if (!_isSearching && _featuredNewsList.isNotEmpty) ...[
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

                    // Categories with Icons
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        child: Text(
                          'Categories',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100, // Increased height for vertical chip feel
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected =
                                category['name'] == _selectedCategory;
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: GestureDetector(
                                onTap: () => _onCategoryChanged(category['name']),
                                child: Column(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.secondary
                                            : Theme.of(context).cardTheme.color,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                      .withOpacity(0.3),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Icon(
                                        category['icon'],
                                        color: isSelected
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (category['name'] as String).toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.secondary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
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

                    // Recent News Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              _isSearching ? 'Search Results' : 'Recent News',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(width: 8),
                            if (!_isSearching && _filteredNewsList.isNotEmpty)
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
                                Icons.search_off_rounded,
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

          // Profile Tab
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddNewsScreen()),
              );
            },
            customBorder: const CircleBorder(),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
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
              const SizedBox(width: 48), // Gap for FAB
              _buildNavItem(
                2,
                Icons.bookmark_rounded,
                Icons.bookmark_rounded,
                'Saved',
              ),
              _buildNavItem(
                3,
                Icons.person_rounded,
                Icons.person_rounded,
                'Profile',
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
            if (index == 0) _loadUserName();
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
