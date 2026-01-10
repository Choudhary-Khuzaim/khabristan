import 'package:flutter/material.dart';
import '../models/news_model.dart';

class BookmarksService extends ChangeNotifier {
  static final BookmarksService _instance = BookmarksService._internal();
  factory BookmarksService() => _instance;
  BookmarksService._internal();

  final List<NewsModel> _bookmarks = [];

  List<NewsModel> get bookmarks => _bookmarks;

  bool isBookmarked(NewsModel news) {
    return _bookmarks.any((item) => item.title == news.title);
  }

  void toggleBookmark(NewsModel news) {
    if (isBookmarked(news)) {
      _bookmarks.removeWhere((item) => item.title == news.title);
    } else {
      _bookmarks.add(news);
    }
    notifyListeners();
  }
}
