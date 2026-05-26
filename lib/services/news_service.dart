import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsService {
  // ============================================
  // Backend API Base URL
  // ============================================
  // IMPORTANT:
  // - If using ANDROID EMULATOR, use: 'http://10.0.2.2:5000/api/v1'
  // - If using iOS SIMULATOR or WEB, use: 'http://localhost:5000/api/v1'
  // - If using a REAL DEVICE, use your PC's IP: 'http://192.168.x.x:5000/api/v1'
  
  // Update: Set to Mac's local network IP for real device testing
  static const String _backendUrl = 'http://192.168.1.4:5000/api/v1';

  // ============================================
  // Get daily news from backend (cached, fast)
  // This is the PRIMARY method for fetching news
  // ============================================
  Future<List<NewsModel>> getTopHeadlines({
    String category = 'general',
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // If query is provided, use search endpoint
      if (query != null && query.isNotEmpty) {
        return await searchNews(query: query, page: page, limit: limit);
      }

      // Use the backend's cached daily endpoint
      String url =
          '$_backendUrl/external-news/daily?category=$category&page=$page&limit=$limit';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final NewsResponse newsResponse = NewsResponse.fromJson(data);
          return newsResponse.articles;
        }
        throw Exception('Backend returned error: ${data['message']}');
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  // ============================================
  // Get featured/breaking news
  // ============================================
  Future<List<NewsModel>> getFeaturedNews({int limit = 5}) async {
    try {
      final url = '$_backendUrl/external-news/featured?limit=$limit';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final NewsResponse newsResponse = NewsResponse.fromJson(data);
          return newsResponse.articles;
        }
        throw Exception('Backend returned error: ${data['message']}');
      } else {
        throw Exception('Failed to load featured news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching featured news: $e');
    }
  }

  // ============================================
  // Search news from backend
  // ============================================
  Future<List<NewsModel>> searchNews({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final url =
          '$_backendUrl/external-news/search?q=${Uri.encodeComponent(query)}&page=$page&limit=$limit';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true) {
          final NewsResponse newsResponse = NewsResponse.fromJson(data);
          return newsResponse.articles;
        }
        throw Exception('Backend returned error: ${data['message']}');
      } else {
        throw Exception('Failed to search news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching news: $e');
    }
  }

  // ============================================
  // Get everything (search via backend proxy)
  // Kept for backward compatibility
  // ============================================
  Future<List<NewsModel>> getEverything({required String query}) async {
    return searchNews(query: query);
  }

  // ============================================
  // Get news stats
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
      throw Exception('Error fetching stats: $e');
    }
  }

  // ============================================
  // Get news by category
  // ============================================
  Future<List<NewsModel>> getNewsByCategory({
    required String category,
    int page = 1,
    int limit = 20,
  }) async {
    return getTopHeadlines(category: category, page: page, limit: limit);
  }
}
