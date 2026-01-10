import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/bookmarks_service.dart';
import '../widgets/news_card.dart';
import 'news_detail_screen.dart';

class SavedNewsScreen extends StatefulWidget {
  const SavedNewsScreen({super.key});

  @override
  State<SavedNewsScreen> createState() => _SavedNewsScreenState();
}

class _SavedNewsScreenState extends State<SavedNewsScreen> {
  final BookmarksService _bookmarksService = BookmarksService();

  @override
  void initState() {
    super.initState();
    _bookmarksService.addListener(_onBookmarksChanged);
  }

  @override
  void dispose() {
    _bookmarksService.removeListener(_onBookmarksChanged);
    super.dispose();
  }

  void _onBookmarksChanged() {
    setState(() {});
  }

  void _navigateToDetail(NewsModel news) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailScreen(news: news)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarks = _bookmarksService.bookmarks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved News'),
        centerTitle: true,
      ),
      body: bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved news yet',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the bookmark icon to save news',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                return NewsCard(
                  news: bookmarks[index],
                  onTap: () => _navigateToDetail(bookmarks[index]),
                );
              },
            ),
    );
  }
}
