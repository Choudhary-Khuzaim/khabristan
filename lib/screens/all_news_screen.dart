import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/news_model.dart';
import '../widgets/news_card.dart';
import 'news_detail_screen.dart';

class AllNewsScreen extends StatelessWidget {
  final String title;
  final List<NewsModel> newsList;

  const AllNewsScreen({
    super.key,
    required this.title,
    required this.newsList,
  });

  void _navigateToDetail(BuildContext context, NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            iconSize: 18,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: newsList.isEmpty
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
                    'No news available',
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: newsList.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: NewsCard(
                          news: newsList[index],
                          onTap: () => _navigateToDetail(context, newsList[index]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
