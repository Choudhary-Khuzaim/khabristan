import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/news_model.dart';
import 'preferences_service.dart';

class NewsService {
  // Get your free API key from: https://newsapi.org/register
  static const String apiKey = '4541103009c94411a7051969a930776b';
  static const String baseUrl = 'https://newsapi.org/v2';

  // Fallback API that doesn't require key (Saurav.tech)
  static const String fallbackUrl = 'https://saurav.tech/NewsAPI';

  final PreferencesService _prefs = PreferencesService();

  Future<List<NewsModel>> getTopHeadlines({String? category}) async {
    try {
      final country = await _prefs.getRegion();

      // 1. Try official NewsAPI first
      if (apiKey != 'YOUR_API_KEY_HERE') {
        final queryParams = {
          'country': country,
          'apiKey': apiKey,
          'pageSize': '30',
        };

        final standardCategories = [
          'business',
          'entertainment',
          'general',
          'health',
          'science',
          'sports',
          'technology',
        ];

        if (category != null) {
          if (standardCategories.contains(category)) {
            queryParams['category'] = category;
          } else {
            queryParams['q'] = category;
          }
        }

        final uri = Uri.parse(
          '$baseUrl/top-headlines',
        ).replace(queryParameters: queryParams);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          final NewsResponse newsResponse = NewsResponse.fromJson(jsonData);

          final recentNews = _filterRecentNews(newsResponse.articles);
          return recentNews.isNotEmpty ? recentNews : newsResponse.articles;
        }
      }

      // 2. Fallback to Saurav.tech
      return await _fetchFromFallback(country, category);
    } catch (e) {
      debugPrint('Error fetching news: $e');
      return _getSampleNews();
    }
  }

  List<NewsModel> _filterRecentNews(List<NewsModel> articles) {
    final now = DateTime.now();
    // Relaxed to 3 days to ensure we have content
    final threeDaysAgo = now.subtract(const Duration(days: 3));

    return articles.where((article) {
      if (article.publishedAt == null) return false;
      try {
        final publishedDate = DateTime.parse(article.publishedAt!);
        return publishedDate.isAfter(threeDaysAgo);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<List<NewsModel>> _fetchFromFallback(
    String country,
    String? category,
  ) async {
    try {
      // Map country codes to what saurav.tech supports (us, in, au, ru, fr, gb)
      // If not supported, default to 'us'
      final supportedCountries = ['us', 'in', 'au', 'ru', 'fr', 'gb'];
      final targetCountry = supportedCountries.contains(country)
          ? country
          : 'us';

      String url;

      final standardCategories = [
        'business',
        'entertainment',
        'general',
        'health',
        'science',
        'sports',
        'technology',
      ];

      if (category != null && standardCategories.contains(category)) {
        url =
            '$fallbackUrl/top-headlines/category/$category/$targetCountry.json';
      } else {
        // Fallback API doesn't support search or other categories, defaulting to general
        url = '$fallbackUrl/top-headlines/category/general/$targetCountry.json';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final NewsResponse newsResponse = NewsResponse.fromJson(jsonData);
        var articles = newsResponse.articles;

        // If it was a search query (not a standard category), filter results client-side
        if (category != null && !standardCategories.contains(category)) {
          final query = category.toLowerCase();
          articles = articles.where((article) {
            final title = article.title?.toLowerCase() ?? '';
            final description = article.description?.toLowerCase() ?? '';
            return title.contains(query) || description.contains(query);
          }).toList();
        }

        final recentNews = _filterRecentNews(articles);
        return recentNews.isNotEmpty ? recentNews : articles;
      } else {
        throw Exception('Fallback API failed');
      }
    } catch (e) {
      debugPrint('Fallback Error: $e');
      return _getSampleNews();
    }
  }

  List<NewsModel> _getSampleNews() {
    // Sample news data for demo purposes (timestamps set to recent)
    return [
      NewsModel(
        title: 'Global Tech Summit 2024 Kicks Off in London',
        description:
            'Innovators from around the world gather to discuss the future of AI and sustainable technology.',
        urlToImage:
            'https://images.unsplash.com/photo-1505373877841-8d25f7d46678?w=800',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        author: 'Tech Global',
        source: 'Tech World',
      ),
      NewsModel(
        title: 'UN Announces New Climate Action Plan',
        description:
            'United Nations delegates have agreed on a comprehensive framework to combat global warming.',
        urlToImage:
            'https://images.unsplash.com/photo-1569163139599-0f4517e36b51?w=800',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
        author: 'World Desk',
        source: 'UN News',
      ),
      NewsModel(
        title: 'International Space Station Welcomes New Crew',
        description:
            'Astronauts from three different space agencies arrived at the ISS today.',
        urlToImage:
            'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=800',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 8))
            .toIso8601String(),
        author: 'Space Corr.',
        source: 'Space Daily',
      ),
      NewsModel(
        title: 'World Cup 2026: Host Cities Finalized',
        description:
            'FIFA has officially announced the final list of host cities for the upcoming World Cup.',
        urlToImage:
            'https://images.unsplash.com/photo-1518091043644-c1d4457512c6?w=800',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 12))
            .toIso8601String(),
        author: 'Sports Ed.',
        source: 'Global Sports',
      ),
      NewsModel(
        title: 'Breakthrough in Renewable Energy Storage',
        description:
            'Scientists in Japan have developed a new battery technology that could double EV range.',
        urlToImage:
            'https://images.unsplash.com/photo-1497435334941-8c899ee9e8e9?w=800',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 15))
            .toIso8601String(),
        author: 'Science Weekly',
        source: 'Future Tech',
      ),
    ];
  }
}
