import 'package:flutter/material.dart';
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

import 'package:animations/animations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  final TextEditingController _searchController = TextEditingController();
  List<NewsModel> _newsList = [];
  List<NewsModel> _featuredNewsList = [];
  List<NewsModel> _filteredNewsList = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _selectedCategory = 'general';
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;

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
    _loadNews();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final news = await _newsService.getTopHeadlines(
        category: _selectedCategory,
      );
      setState(() {
        _newsList = news;
        _filteredNewsList = news;
        // Take top 5 for featured, rest for list if general category
        if (_selectedCategory == 'general' && news.isNotEmpty) {
          _featuredNewsList = news.take(5).toList();
        } else {
          _featuredNewsList = [];
        }
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
          return title.contains(searchQuery) || description.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _navigateToDetail(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List of screens for bottom navigation
    final List<Widget> screens = [
      // Home Tab Content
      SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNews,
          color: Theme.of(context).colorScheme.primary,
          child: AnimationLimiter(
            child: CustomScrollView(
              controller: _scrollController,
            slivers: [
              // Custom App Bar
              SliverAppBar(
                floating: true,
                pinned: false,
                snap: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.newspaper_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'KhabarIsTan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                actions: [], // Removed Profile Icon
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterNews,
                    decoration: InputDecoration(
                      hintText: 'Search for news...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                _filterNews('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // Featured News Carousel (Only show if not searching and has items)
              if (!_isSearching && _featuredNewsList.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Breaking News',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllNewsScreen(
                                  title: 'Breaking News',
                                  newsList: _newsList,
                                ),
                              ),
                            );
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 280,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.9),
                      padEnds: false,
                      itemCount: _featuredNewsList.length,
                      itemBuilder: (context, index) {
                        return FeaturedNewsCard(
                          news: _featuredNewsList[index],
                          onTap: () => _navigateToDetail(_featuredNewsList[index]),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],

              // Categories
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category['name'] == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text(
                            (category['name'] as String).toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              _onCategoryChanged(category['name']);
                            }
                          },
                          backgroundColor: Theme.of(context).cardTheme.color,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Recent News Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text(
                    _isSearching ? 'Search Results' : 'Recent News',
                    style: Theme.of(context).textTheme.titleLarge,
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
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: NewsCard(
                              news: _filteredNewsList[index],
                              onTap: () => _navigateToDetail(_filteredNewsList[index]),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _filteredNewsList.length,
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
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
    ];

    return Scaffold(
      body: screens[_currentIndex],
      floatingActionButton: OpenContainer(
        transitionDuration: const Duration(milliseconds: 800), // Slightly faster
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (context, _) => const AddNewsScreen(),
        closedElevation: 0,
        closedShape: const CircleBorder(),
        closedColor: Colors.transparent, // Important for the gradient to show
        // The container itself is the tappable area
        closedBuilder: (context, openContainer) {
          return Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Theme.of(context).cardTheme.color,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0), // Minimal horizontal padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
              
              const SizedBox(width: 48), // Gap for FAB
              
              _buildNavItem(2, Icons.bookmark_rounded, Icons.bookmark_border_rounded, 'Saved'),
              _buildNavItem(3, Icons.person_rounded, Icons.person_outline, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
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
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
