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

  @override
  void initState() {
    super.initState();
    _myNewsFuture = _prefs.getMyNews();
  }

  void _navigateToDetail(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Published News'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<NewsModel>>(
        future: _myNewsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading news: ${snapshot.error}'),
            );
          }

          final newsList = snapshot.data ?? [];

          if (newsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No published news yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to profile, or use home nav mechanism
                      // Ideally, user would tap the + button
                    },
                    child: const Text('Go Publish Something!'),
                  ),
                ],
              ),
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Dismissible(
                        key: Key(newsList[index].publishedAt ?? newsList[index].hashCode.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white, size: 30),
                        ),
                        onDismissed: (direction) async {
                          final newsToDelete = newsList[index];
                          
                          // Remove from UI immediately
                          setState(() {
                            // snapshot.data is usually immutable or from Future, so we need a mutable list
                            // But here we are relying on FutureBuilder re-triggering or optimistic updates.
                            // Better approach: remove from local list copy if we had one, but we are using FutureBuilder directly.
                            // Simple fix: Wait for async op and reload.
                          });
                          
                          await _prefs.deleteMyNews(newsToDelete);
                          
                          // Refresh the list
                          setState(() {
                             _myNewsFuture = _prefs.getMyNews();
                          });

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('News deleted'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () async {
                                    await _prefs.saveMyNews(newsToDelete);
                                    setState(() {
                                      _myNewsFuture = _prefs.getMyNews();
                                    });
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: NewsCard(
                          news: newsList[index],
                          onTap: () => _navigateToDetail(newsList[index]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
