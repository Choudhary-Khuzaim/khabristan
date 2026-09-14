import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/news_model.dart';

class NewsService {
  // ============================================
  // Google News RSS URLs (Direct — no backend needed)
  // ============================================
  static const String _googleNewsBase = 'https://news.google.com/rss';

  // Backend URL (used ONLY as fallback, and for user-posted news, auth, bookmarks)
  // IMPORTANT:
  // - If using ANDROID EMULATOR, use: 'http://10.0.2.2:5000/api/v1'
  // - If using iOS SIMULATOR or WEB, use: 'http://localhost:5000/api/v1'
  // - If using a REAL DEVICE, use your PC's IP: 'http://192.168.x.x:5000/api/v1'
  static const String _backendUrl = 'http://192.168.1.3:5000/api/v1';

  // ============================================
  // Category to Google News RSS topic mapping
  // ============================================
  static const Map<String, String> _categoryTopicMap = {
    'general': '',
    'business': 'BUSINESS',
    'entertainment': 'ENTERTAINMENT',
    'health': 'HEALTH',
    'science': 'SCIENCE',
    'sports': 'SPORTS',
    'technology': 'TECHNOLOGY',
  };

  // ============================================
  // PRIMARY: Get top headlines directly from Google News RSS
  // ============================================
  Future<List<NewsModel>> getTopHeadlines({
    String category = 'general',
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    // If query is provided, use search
    if (query != null && query.isNotEmpty) {
      return await searchNews(query: query, page: page, limit: limit);
    }

    try {
      final articles = await _fetchFromGoogleRss(category: category);

      // Apply pagination
      final startIndex = (page - 1) * limit;
      if (startIndex >= articles.length) return [];
      final endIndex = (startIndex + limit).clamp(0, articles.length);

      return articles.sublist(startIndex, endIndex);
    } catch (e) {
      // Fallback to backend if Google News RSS fails
      try {
        return await _fallbackToBackend(category: category, page: page, limit: limit);
      } catch (_) {
        throw Exception('Error fetching news: $e');
      }
    }
  }

  // ============================================
  // Get featured/breaking news (top 5 from general)
  // ============================================
  Future<List<NewsModel>> getFeaturedNews({int limit = 5}) async {
    try {
      final articles = await _fetchFromGoogleRss(category: 'general');

      // Pick top articles (they come in reverse chronological order from RSS)
      return articles.take(limit).toList();
    } catch (e) {
      // Fallback to backend
      try {
        final url = '$_backendUrl/external-news/featured?limit=$limit';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['success'] == true) {
            return NewsResponse.fromJson(data).articles;
          }
        }
      } catch (_) {}
      throw Exception('Error fetching featured news: $e');
    }
  }

  // ============================================
  // Search news from Google News RSS
  // ============================================
  Future<List<NewsModel>> searchNews({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final rssUrl =
          '$_googleNewsBase/search?q=${Uri.encodeComponent(query)}&hl=en-US&gl=US&ceid=US:en';

      final articles = await _parseRssFeed(rssUrl);

      // Apply pagination
      final startIndex = (page - 1) * limit;
      if (startIndex >= articles.length) return [];
      final endIndex = (startIndex + limit).clamp(0, articles.length);

      return articles.sublist(startIndex, endIndex);
    } catch (e) {
      // Fallback: try backend search
      try {
        final url =
            '$_backendUrl/external-news/search?q=${Uri.encodeComponent(query)}&page=$page&limit=$limit';
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['success'] == true) {
            return NewsResponse.fromJson(data).articles;
          }
        }
      } catch (_) {}
      throw Exception('Error searching news: $e');
    }
  }

  // ============================================
  // Get everything (backward compatible)
  // ============================================
  Future<List<NewsModel>> getEverything({required String query}) async {
    return searchNews(query: query);
  }

  // ============================================
  // Get news stats (from backend if available)
  // ============================================
  Future<Map<String, dynamic>> getNewsStats() async {
    try {
      const url = '$_backendUrl/external-news/stats';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
        throw Exception('Backend returned error: ${data['message']}');
      }
      throw Exception('Failed to load stats: ${response.statusCode}');
    } catch (e) {
      // Return basic stats if backend is not available
      return {
        'totalArticles': 0,
        'todayArticles': 0,
        'lastUpdated': DateTime.now().toIso8601String(),
        'source': 'offline',
      };
    }
  }

  // ============================================
  // Get news by category (backward compatible)
  // ============================================
  Future<List<NewsModel>> getNewsByCategory({
    required String category,
    int page = 1,
    int limit = 20,
  }) async {
    return getTopHeadlines(category: category, page: page, limit: limit);
  }

  // ============================================
  // PRIVATE: Fetch from Google News RSS by category
  // ============================================
  Future<List<NewsModel>> _fetchFromGoogleRss({
    String category = 'general',
    String country = 'us',
  }) async {
    String rssUrl;

    final topic = _categoryTopicMap[category.toLowerCase()] ?? '';

    if (topic.isEmpty) {
      // General — top headlines
      rssUrl = '$_googleNewsBase?hl=en-${country.toUpperCase()}&gl=${country.toUpperCase()}&ceid=${country.toUpperCase()}:en';
    } else {
      // Specific category
      rssUrl = '$_googleNewsBase/headlines/section/topic/$topic?hl=en-${country.toUpperCase()}&gl=${country.toUpperCase()}&ceid=${country.toUpperCase()}:en';
    }

    return await _parseRssFeed(rssUrl);
  }

  // ============================================
  // PRIVATE: Parse RSS XML feed into NewsModel list
  // ============================================
  Future<List<NewsModel>> _parseRssFeed(String rssUrl) async {
    final response = await http
        .get(
          Uri.parse(rssUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('RSS feed returned status: ${response.statusCode}');
    }

    final xmlString = response.body;
    final document = xml.XmlDocument.parse(xmlString);

    final items = document.findAllElements('item');
    final List<NewsModel> articles = [];

    for (final item in items) {
      final rssData = <String, String>{};

      // Extract title
      final titleElement = item.findElements('title').firstOrNull;
      rssData['title'] = titleElement?.innerText ?? '';

      // Extract link
      final linkElement = item.findElements('link').firstOrNull;
      rssData['link'] = linkElement?.innerText ?? '';

      // Extract pubDate
      final pubDateElement = item.findElements('pubDate').firstOrNull;
      rssData['pubDate'] = pubDateElement?.innerText ?? '';

      // Extract description
      final descElement = item.findElements('description').firstOrNull;
      rssData['description'] = descElement?.innerText ?? '';

      // Extract source
      final sourceElement = item.findElements('source').firstOrNull;
      rssData['source'] = sourceElement?.innerText ?? 'Google News';

      // Skip items without title
      final title = rssData['title'] ?? '';
      if (title.isEmpty || title == '[Removed]') continue;

      articles.add(NewsModel.fromRss(rssData));
    }

    return articles;
  }

  // ============================================
  // PRIVATE: Fallback to backend API
  // ============================================
  Future<List<NewsModel>> _fallbackToBackend({
    String category = 'general',
    int page = 1,
    int limit = 20,
  }) async {
    final url =
        '$_backendUrl/external-news/daily?category=$category&page=$page&limit=$limit';

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['success'] == true) {
        return NewsResponse.fromJson(data).articles;
      }
      throw Exception('Backend returned error: ${data['message']}');
    }
    throw Exception('Backend returned status: ${response.statusCode}');
  }
}
