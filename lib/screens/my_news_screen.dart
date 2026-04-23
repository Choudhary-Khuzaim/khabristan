import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/news_model.dart';
import '../services/preferences_service.dart';
import '../widgets/news_card.dart';
import 'news_detail_screen.dart';

class MyNewsScreen extends StatefulWidget {
  const MyNewsScreen({super.key});

  @override
  State<MyNewsScreen> createState() => _MyNewsScreenState();
}
class _MyNewsScreenState extends State<MyNewsScreen> {
  final PreferencesService _prefs = PreferencesService();
  late Future<List<NewsModel>> _myNewsFuture;
  List<NewsModel>? _localNewsList;

  @override
  void initState() {
    super.initState();
    _myNewsFuture = _prefs.getMyNews();
  }

  void _navigateToDetail(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(
          news: news,
          heroTag: 'news_card_${news.url ?? news.title}_${news.publishedAt ?? 'now'}',
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
                'My Publications',
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
          FutureBuilder<List<NewsModel>>(
            future: _myNewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text('Error loading news: ${snapshot.error}'),
                  ),
                );
              }

              if (_localNewsList == null) {
                _localNewsList = List.from(snapshot.data ?? []);
              }
              final newsList = _localNewsList!;

              if (newsList.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.article_rounded,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Articles Found',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You haven\'t published any stories yet.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Start Writing',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Dismissible(
                                key: ValueKey(
                                  '${newsList[index].url}_${newsList[index].title}_$index',
                                ),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Icon(
                                    Icons.delete_sweep_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  final newsToDelete = newsList[index];
                                  setState(() {
                                    _localNewsList!.removeAt(index);
                                  });
                                  await _prefs.deleteMyNews(newsToDelete);
                                  _myNewsFuture = _prefs.getMyNews();

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Entry removed'),
                                        behavior: SnackBarBehavior.floating,
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          onPressed: () async {
                                              await _prefs.saveMyNews(
                                                newsToDelete,
                                              );
                                              final updated =
                                                  await _prefs.getMyNews();
                                              setState(() {
                                                _localNewsList = updated;
                                                _myNewsFuture =
                                                    Future.value(updated);
                                              });
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: NewsCard(
                                  news: newsList[index],
                                  onTap: () =>
                                      _navigateToDetail(newsList[index]),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: newsList.length),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
