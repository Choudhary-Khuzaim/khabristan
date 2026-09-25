import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
import '../widgets/glass_background.dart';
import '../widgets/news_card.dart';
import '../widgets/shimmer_loading.dart';
import 'news_detail_screen.dart';

class SourceNewsScreen extends StatefulWidget {
  final String sourceName;
  final String sourceUrl;

  const SourceNewsScreen({
    super.key,
    required this.sourceName,
    required this.sourceUrl,
  });

  @override
  State<SourceNewsScreen> createState() => _SourceNewsScreenState();
}

class _SourceNewsScreenState extends State<SourceNewsScreen> {
  final NewsService _newsService = NewsService();
  List<NewsModel> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNewsWithCache();
  }

  /// Cache-first: show cached data instantly, then refresh in background
  Future<void> _loadNewsWithCache() async {
    // Try to show cached data instantly
    final cached = _newsService.getCachedNewsBySource(
      widget.sourceUrl,
      widget.sourceName,
    );

    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _newsList = cached;
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
    try {
      final news = await _newsService.getNewsBySource(
        widget.sourceUrl,
        widget.sourceName,
      );
      if (mounted && news.isNotEmpty) {
        setState(() {
          _newsList = news;
        });
      }
    } catch (_) {
      // Silently ignore — we already have cached data showing
    }
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final news = await _newsService.getNewsBySource(
        widget.sourceUrl,
        widget.sourceName,
      );
      if (mounted) {
        setState(() {
          _newsList = news;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading news: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToDetail(NewsModel news, String heroTag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(news: news, heroTag: heroTag),
      ),
    );
  }

  String _getDomain(String url) {
    try {
      return Uri.parse(url).host.replaceAll('www.', '');
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = _getDomain(widget.sourceUrl);
    final logoUrl =
        domain.isNotEmpty ? 'https://logo.clearbit.com/$domain' : '';

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (logoUrl.isNotEmpty) ...[
                Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(widget.sourceName),
            ],
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _loadNews,
          color: Theme.of(context).colorScheme.primary,
          child: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: 5,
                  itemBuilder: (context, index) => const NewsCardShimmer(),
                )
              : _newsList.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
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
                                  'No news found for ${widget.sourceName}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : AnimationLimiter(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _newsList.length,
                        itemBuilder: (context, index) {
                          final news = _newsList[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: NewsCard(
                                  news: news,
                                  heroPrefix:
                                      'source_news_${widget.sourceName}',
                                  onTap: () => _navigateToDetail(
                                    news,
                                    'source_news_${widget.sourceName}_${news.url ?? news.title}_${news.publishedAt ?? 'now'}',
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
