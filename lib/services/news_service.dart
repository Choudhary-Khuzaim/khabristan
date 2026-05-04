import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_model.dart';

class NewsService {
  // IMPORTANT: Get your free API key at https://newsapi.org/
  static const String _apiKey = '7011d13788754be985396556f8490a2a'; // Replace with your actual API key
  static const String _baseUrl = 'https://newsapi.org/v2';

  Future<List<NewsModel>> getTopHeadlines({String category = 'general', String? query}) async {
    try {
      String url = '$_baseUrl/top-headlines?apiKey=$_apiKey&country=us&category=$category';
      if (query != null && query.isNotEmpty) {
        url += '&q=$query';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final NewsResponse newsResponse = NewsResponse.fromJson(data);
        return newsResponse.articles;
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  Future<List<NewsModel>> getEverything({required String query}) async {
    try {
      final url = '$_baseUrl/everything?q=$query&apiKey=$_apiKey';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final NewsResponse newsResponse = NewsResponse.fromJson(data);
        return newsResponse.articles;
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }
}
