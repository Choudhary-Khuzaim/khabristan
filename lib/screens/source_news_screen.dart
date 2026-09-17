import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';
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
    _loadNews();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sourceName),
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
                ? Center(
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
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
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
                                heroPrefix: 'source_news_${widget.sourceName}',
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
    );
  }
}
