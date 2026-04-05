import 'package:flutter/material.dart';
import '../models/news_model.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarksService extends ChangeNotifier {
  static final BookmarksService _instance = BookmarksService._internal();
  factory BookmarksService() => _instance;
  BookmarksService._internal();

  final List<NewsModel> _bookmarks = [];
  static const String _keyBookmarks = 'bookmarks';
  bool _isInitialized = false;

  List<NewsModel> get bookmarks => _bookmarks;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    await _loadBookmarks();
    _isInitialized = true;
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = prefs.getStringList(_keyBookmarks) ?? [];

      _bookmarks.clear();
      for (String jsonStr in jsonList) {
        try {
          final Map<String, dynamic> map = jsonDecode(jsonStr);
          _bookmarks.add(NewsModel.fromJson(map));
        } catch (e) {
          debugPrint('Error parsing bookmark: $e');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing BookmarksService: $e');
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = _bookmarks
          .map((news) => jsonEncode(news.toJson()))
          .toList();
      await prefs.setStringList(_keyBookmarks, jsonList);
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  bool isBookmarked(NewsModel news) {
    return _bookmarks.any(
      (item) => item.title == news.title && item.url == news.url,
    );
  }

  void toggleBookmark(NewsModel news) {
    if (isBookmarked(news)) {
      _bookmarks.removeWhere(
        (item) => item.title == news.title && item.url == news.url,
      );
    } else {
      _bookmarks.add(news);
    }
    _saveBookmarks();
    notifyListeners();
  }
}
