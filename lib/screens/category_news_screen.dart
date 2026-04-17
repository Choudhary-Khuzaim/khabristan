import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../widgets/news_card.dart';
import '../widgets/shimmer_loading.dart';
import 'news_detail_screen.dart';

class CategoryNewsScreen extends StatefulWidget {
  final String category;

  const CategoryNewsScreen({super.key, required this.category});

  @override
  State<CategoryNewsScreen> createState() => _CategoryNewsScreenState();
}

class _CategoryNewsScreenState extends State<CategoryNewsScreen> {
  final NewsService _newsService = NewsService();
  List<NewsModel> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final news = await _newsService.getTopHeadlines(
        category: widget.category.toLowerCase(),
      );
      setState(() {
        _newsList = news;
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
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToDetail(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(
          news: news,
          heroTag: '${news.url}_${news.publishedAt}_card',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.category,
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
          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const NewsCardShimmer(),
                childCount: 6,
              ),
            )
          else if (_newsList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_rounded,
                      size: 64,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No stories found in ${widget.category}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NewsCard(
                      news: _newsList[index],
                      onTap: () => _navigateToDetail(_newsList[index]),
                    ),
                  );
                }, childCount: _newsList.length),
              ),
            ),

        ],
      ),
    );
  }
}
