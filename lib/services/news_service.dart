import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/news_model.dart';

class NewsService {
  // ============================================
  // Multi-Source RSS Feeds (PlayStore Safe)
  // Each publisher's own RSS feed — no Google News dependency
  // ============================================

  // Cache to instantly load news on tab switches or duplicate calls
  static List<NewsModel>? _cachedGeneralNews;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 3);

  // Fastest and most reliable feeds for quick initial load
  static const List<String> _priorityFeeds = [
    'BBC News',
    'CNN',
    'Dawn',
    'Al Jazeera',
    'The New York Times',
    'Reuters'
  ];

  /// Category-to-RSS mapping: 60+ worldwide major news sources
  /// All feeds are from individual publishers — PlayStore safe
  static const Map<String, List<Map<String, String>>> _categoryFeeds = {
    'general': [
      // === INTERNATIONAL GIANTS ===
      {'name': 'BBC News', 'url': 'https://feeds.bbci.co.uk/news/rss.xml'},
      {'name': 'BBC World', 'url': 'https://feeds.bbci.co.uk/news/world/rss.xml'},
      {'name': 'The New York Times', 'url': 'https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml'},
      {'name': 'NYT World', 'url': 'https://rss.nytimes.com/services/xml/rss/nyt/World.xml'},
      {'name': 'Al Jazeera', 'url': 'https://www.aljazeera.com/xml/rss/all.xml'},
      {'name': 'Reuters', 'url': 'https://www.reutersagency.com/feed/?taxonomy=best-sectors&post_type=best'},
      {'name': 'The Guardian', 'url': 'https://www.theguardian.com/world/rss'},
      {'name': 'CNN', 'url': 'http://rss.cnn.com/rss/edition.rss'},
      {'name': 'CNN World', 'url': 'http://rss.cnn.com/rss/edition_world.rss'},
      {'name': 'NPR', 'url': 'https://feeds.npr.org/1001/rss.xml'},
      {'name': 'ABC News', 'url': 'https://abcnews.go.com/abcnews/topstories'},
      {'name': 'CBS News', 'url': 'https://www.cbsnews.com/latest/rss/main'},
      {'name': 'NBC News', 'url': 'https://feeds.nbcnews.com/nbcnews/public/news'},
      {'name': 'Fox News', 'url': 'https://moxie.foxnews.com/google-publisher/latest.xml'},
      {'name': 'Sky News', 'url': 'https://feeds.skynews.com/feeds/rss/home.xml'},
      {'name': 'The Independent', 'url': 'https://www.independent.co.uk/news/world/rss'},
      {'name': 'USA Today', 'url': 'https://rssfeeds.usatoday.com/usatoday-NewsTopStories'},
      {'name': 'Washington Post', 'url': 'https://feeds.washingtonpost.com/rss/world'},
      // === EUROPEAN / GLOBAL ===
      {'name': 'DW News', 'url': 'https://rss.dw.com/rdf/rss-en-all'},
      {'name': 'France 24', 'url': 'https://www.france24.com/en/rss'},
      {'name': 'The Telegraph', 'url': 'https://www.telegraph.co.uk/rss.xml'},
      {'name': 'Irish Times', 'url': 'https://www.irishtimes.com/cmlink/news-1.1319192'},
      // === PAKISTAN ===
      {'name': 'Dawn', 'url': 'https://www.dawn.com/feeds/home'},
      {'name': 'Geo News', 'url': 'https://www.geo.tv/rss/1/1'},
      {'name': 'The News International', 'url': 'https://www.thenews.com.pk/rss/1/1'},
      {'name': 'Express Tribune', 'url': 'https://tribune.com.pk/feed/home'},
      // === SOUTH ASIA ===
      {'name': 'NDTV', 'url': 'https://feeds.feedburner.com/ndtvnews-top-stories'},
      {'name': 'Times of India', 'url': 'https://timesofindia.indiatimes.com/rssfeedstopstories.cms'},
      {'name': 'The Hindu', 'url': 'https://www.thehindu.com/news/feeder/default.rss'},
      // === MIDDLE EAST ===
      {'name': 'Arab News', 'url': 'https://www.arabnews.com/rss.xml'},
    ],
    'business': [
      {'name': 'BBC Business', 'url': 'https://feeds.bbci.co.uk/news/business/rss.xml'},
      {'name': 'NYT Business', 'url': 'https://rss.nytimes.com/services/xml/rss/nyt/Business.xml'},
      {'name': 'CNBC', 'url': 'https://search.cnbc.com/rs/search/combinedcms/view.xml?partnerId=wrss01&id=10001147'},
      {'name': 'The Guardian Business', 'url': 'https://www.theguardian.com/uk/business/rss'},
      {'name': 'MarketWatch', 'url': 'https://feeds.marketwatch.com/marketwatch/topstories/'},
      {'name': 'NPR Business', 'url': 'https://feeds.npr.org/1006/rss.xml'},
      {'name': 'Forbes', 'url': 'https://www.forbes.com/business/feed/'},
      {'name': 'Business Insider', 'url': 'https://www.businessinsider.com/rss'},
      {'name': 'CNN Business', 'url': 'http://rss.cnn.com/rss/money_news_international.rss'},
      {'name': 'Sky News Business', 'url': 'https://feeds.skynews.com/feeds/rss/business.xml'},
      {'name': 'DW Business', 'url': 'https://rss.dw.com/rdf/rss-en-bus'},
      {'name': 'Dawn Business', 'url': 'https://www.dawn.com/feeds/business'},
      {'name': 'Washington Post Business', 'url': 'https://feeds.washingtonpost.com/rss/business'},
    ],
    'entertainment': [
      {'name': 'BBC Entertainment', 'url': 'https://feeds.bbci.co.uk/news/entertainment_and_arts/rss.xml'},
      {'name': 'NYT Arts', 'url': 'https://rss.nytimes.com/services/xml/rss/nyt/Arts.xml'},
      {'name': 'The Guardian Culture', 'url': 'https://www.theguardian.com/uk/culture/rss'},
      {'name': 'Variety', 'url': 'https://variety.com/feed/'},
      {'name': 'Hollywood Reporter', 'url': 'https://www.hollywoodreporter.com/feed/'},
      {'name': 'Deadline', 'url': 'https://deadline.com/feed/'},
      {'name': 'Rolling Stone', 'url': 'https://www.rollingstone.com/feed/'},
      {'name': 'Billboard', 'url': 'https://www.billboard.com/feed/'},
      {'name': 'CNN Entertainment', 'url': 'http://rss.cnn.com/rss/edition_entertainment.rss'},
      {'name': 'E! Online', 'url': 'https://www.eonline.com/syndication/feeds/rssfeeds/topstories.xml'},
      {'name': 'Dawn Entertainment', 'url': 'https://www.dawn.com/feeds/entertainment'},
    ],
    'health': [
      {'name': 'BBC Health', 'url': 'https://feeds.bbci.co.uk/news/health/rss.xml'},
      {'name': 'NYT Health', 'url': 'https://rss.nytimes.com/services/xml/rss/nyt/Health.xml'},
      {'name': 'The Guardian Health', 'url': 'https://www.theguardian.com/lifeandstyle/health-and-wellbeing/rss'},
      {'name': 'WebMD', 'url': 'https://rssfeeds.webmd.com/rss/rss.aspx?RSSSource=RSS_PUBLIC'},
      {'name': 'Medical News Today', 'url': 'https://www.medicalnewstoday.com/newsfeeds/rss'},
      {'name': 'NPR Health', 'url': 'https://feeds.npr.org/103537970/rss.xml'},
      {'name': 'CNN Health', 'url': 'http://rss.cnn.com/rss/edition_connecttheworld.rss'},
      {'name': 'WHO News', 'url': 'https://www.who.int/rss-feeds/news-english.xml'},
    ],
    'science': [
      {'name': 'BBC Science', 'url': 'https://feeds.bbci.co.uk/news/science_and_environment/rss.xml'},
      {'name': 'NYT Science', 'url': 'https://rss.nytimes.com/services/xml/rss/nyt/Science.xml'},
      {'name': 'The Guardian Science', 'url': 'https://www.theguardian.com/science/rss'},
      {'name': 'Space.com', 'url': 'https://www.space.com/feeds/all'},
      {'name': 'Live Science', 'url': 'https://www.livescience.com/feeds/all'},
      {'name': 'NPR Science', 'url': 'https://feeds.npr.org/1007/rss.xml'},
      {'name': 'Nature', 'url': 'https://www.nature.com/nature.rss'},
      {'name': 'Scientific American', 'url': 'https://rss.sciam.com/ScientificAmerican-Global'},
      {'name': 'New Scientist', 'url': 'https://www.newscientist.com/section/news/feed/'},
      {'name': 'Phys.org', 'url': 'https://phys.org/rss-feed/'},
      {'name': 'DW Science', 'url': 'https://rss.dw.com/rdf/rss-en-sci'},
    ],
    'sports': [
      {'name': 'BBC Sport', 'url': 'https://feeds.bbci.co.uk/sport/rss.xml'},
      {'name': 'ESPN', 'url': 'https://www.espn.com/espn/rss/news'},
      {'name': 'NYT Sports', 'url': 'https://rss.nytimes.com/services/xml/rss/nyt/Sports.xml'},
      {'name': 'The Guardian Sport', 'url': 'https://www.theguardian.com/uk/sport/rss'},
      {'name': 'Sky Sports', 'url': 'https://www.skysports.com/rss/12040'},
      {'name': 'CBS Sports', 'url': 'https://www.cbssports.com/rss/headlines/'},
      {'name': 'CNN Sport', 'url': 'http://rss.cnn.com/rss/edition_sport.rss'},
      {'name': 'Bleacher Report', 'url': 'https://bleacherreport.com/articles/feed'},
      {'name': 'Dawn Sports', 'url': 'https://www.dawn.com/feeds/sport'},
      {'name': 'Fox Sports', 'url': 'https://api.foxsports.com/v2/content/optimized-rss?partnerKey=MB0Wehpmuj2lUhuRhQaafhBjAJqaPU244byPn1YI&size=30'},
    ],
    'technology': [
      {'name': 'BBC Technology', 'url': 'https://feeds.bbci.co.uk/news/technology/rss.xml'},
      {'name': 'NYT Technology', 'url': 'https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml'},
      {'name': 'TechCrunch', 'url': 'https://techcrunch.com/feed/'},
      {'name': 'The Verge', 'url': 'https://www.theverge.com/rss/index.xml'},
      {'name': 'Ars Technica', 'url': 'https://feeds.arstechnica.com/arstechnica/index'},
      {'name': 'Wired', 'url': 'https://www.wired.com/feed/rss'},
      {'name': 'The Guardian Tech', 'url': 'https://www.theguardian.com/uk/technology/rss'},
      {'name': 'Engadget', 'url': 'https://www.engadget.com/rss.xml'},
      {'name': 'CNET', 'url': 'https://www.cnet.com/rss/news/'},
      {'name': 'ZDNet', 'url': 'https://www.zdnet.com/news/rss.xml'},
      {'name': 'Mashable', 'url': 'https://mashable.com/feeds/rss/all'},
      {'name': 'CNN Tech', 'url': 'http://rss.cnn.com/rss/edition_technology.rss'},
      {'name': 'Sky News Tech', 'url': 'https://feeds.skynews.com/feeds/rss/technology.xml'},
      {'name': 'Forbes Tech', 'url': 'https://www.forbes.com/innovation/feed/'},
      {'name': 'Dawn Tech', 'url': 'https://www.dawn.com/feeds/tech'},
    ],
  };

  // ============================================
  // Get all unique sources across all categories
  // ============================================
  List<Map<String, String>> getAllSources() {
    final Map<String, Map<String, String>> uniqueSources = {};
    for (final category in _categoryFeeds.values) {
      for (final source in category) {
        if (!uniqueSources.containsKey(source['name'])) {
          uniqueSources[source['name']!] = source;
        }
      }
    }
    final sortedSources = uniqueSources.values.toList();
    sortedSources.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    return sortedSources;
  }

  // ============================================
  // Get news for a specific source
  // ============================================
  Future<List<NewsModel>> getNewsBySource(String sourceUrl, String sourceName) async {
    try {
      final articles = await _parseRssFeed(sourceUrl, sourceName: sourceName);
      
      // Sort by date (newest first)
      articles.sort((a, b) {
        final dateA = DateTime.tryParse(a.publishedAt ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b.publishedAt ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });
      
      return articles;
    } catch (e) {
      throw Exception('Error fetching news for $sourceName: $e');
    }
  }

  // Backend URL — automatically detected based on platform
  static String get _backendUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api/v1';
      } else if (Platform.isIOS) {
        return 'http://localhost:5000/api/v1';
      }
    } catch (_) {}
    return 'http://localhost:5000/api/v1';
  }

  // ============================================
  // Track last update time for UI display
  // ============================================
  DateTime? _lastFetchTime;
  DateTime? get lastFetchTime => _lastFetchTime;

  // ============================================
  // PRIMARY: Get top headlines from multiple RSS sources
  // ============================================
  Future<List<NewsModel>> getTopHeadlines({
    String category = 'general',
    String? query,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    // If query is provided, use search
    if (query != null && query.isNotEmpty) {
      return await searchNews(query: query, page: page, limit: limit);
    }

    // Return cached general news if valid
    if (category.toLowerCase() == 'general' && !forceRefresh) {
      if (_cachedGeneralNews != null && _cacheTimestamp != null) {
        if (DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
          final articles = _cachedGeneralNews!;
          final startIndex = (page - 1) * limit;
          if (startIndex >= articles.length) return [];
          final endIndex = (startIndex + limit).clamp(0, articles.length);
          return articles.sublist(startIndex, endIndex);
        }
      }
    }

    try {
      // For general category, use priority feeds on first load to speed up app startup
      final isInitialLoad = category.toLowerCase() == 'general' && _cachedGeneralNews == null;
      
      final articles = await _fetchFromMultipleSources(
        category: category, 
        usePriorityFeedsOnly: isInitialLoad
      );
      
      _lastFetchTime = DateTime.now();

      // Update cache
      if (category.toLowerCase() == 'general') {
        _cachedGeneralNews = articles;
        _cacheTimestamp = DateTime.now();
      }

      // Apply pagination
      final startIndex = (page - 1) * limit;
      if (startIndex >= articles.length) return [];
      final endIndex = (startIndex + limit).clamp(0, articles.length);

      return articles.sublist(startIndex, endIndex);
    } catch (e) {
      // Fallback to backend
      try {
        final result = await _fallbackToBackend(category: category, page: page, limit: limit);
        _lastFetchTime = DateTime.now();
        return result;
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
      // Reuse cached data if available to prevent duplicate 28 HTTP requests
      List<NewsModel> articles;
      if (_cachedGeneralNews != null && _cacheTimestamp != null && 
          DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
        articles = _cachedGeneralNews!;
      } else {
        articles = await _fetchFromMultipleSources(category: 'general', usePriorityFeedsOnly: true);
      }

      // Pick top articles sorted by date (most recent first)
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
  // Get trending/breaking news — real-time latest
  // ============================================
  Future<List<NewsModel>> getTrendingNews({int limit = 10}) async {
    try {
      final generalArticles = await _fetchFromMultipleSources(category: 'general');
      _lastFetchTime = DateTime.now();

      // Already sorted by date from _fetchFromMultipleSources
      return generalArticles.take(limit).toList();
    } catch (e) {
      throw Exception('Error fetching trending news: $e');
    }
  }

  // ============================================
  // Search news — searches across all available sources
  // ============================================
  Future<List<NewsModel>> searchNews({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // Fetch from all categories in parallel and search locally
      final allArticles = <NewsModel>[];
      final categoriesToSearch = ['general', 'technology', 'business', 'science'];

      final futures = categoriesToSearch.map(
        (cat) => _fetchFromMultipleSources(category: cat).catchError((_) => <NewsModel>[]),
      );

      final results = await Future.wait(futures);
      for (final result in results) {
        allArticles.addAll(result);
      }

      // Filter by search query
      final queryLower = query.toLowerCase();
      final filtered = allArticles.where((article) {
        final title = article.title?.toLowerCase() ?? '';
        final description = article.description?.toLowerCase() ?? '';
        final source = article.source?.toLowerCase() ?? '';
        return title.contains(queryLower) ||
            description.contains(queryLower) ||
            source.contains(queryLower);
      }).toList();

      // Deduplicate
      final deduplicated = _deduplicateArticles(filtered);
      _lastFetchTime = DateTime.now();

      // Apply pagination
      final startIndex = (page - 1) * limit;
      if (startIndex >= deduplicated.length) return [];
      final endIndex = (startIndex + limit).clamp(0, deduplicated.length);

      return deduplicated.sublist(startIndex, endIndex);
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
            _lastFetchTime = DateTime.now();
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
      final url = '$_backendUrl/external-news/stats';
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
  // PRIVATE: Fetch from multiple RSS sources for a category
  // ============================================
  Future<List<NewsModel>> _fetchFromMultipleSources({
    String category = 'general',
    bool usePriorityFeedsOnly = false,
  }) async {
    var feeds = _categoryFeeds[category.toLowerCase()] ?? _categoryFeeds['general']!;

    if (usePriorityFeedsOnly && category.toLowerCase() == 'general') {
      feeds = feeds.where((feed) => _priorityFeeds.contains(feed['name'])).toList();
    }

    // Fetch from all selected sources in parallel
    final futures = feeds.map((feed) async {
      try {
        return await _parseRssFeed(
          feed['url']!,
          category: category,
          sourceName: feed['name'] ?? 'News',
        );
      } catch (e) {
        debugPrint('Failed to fetch from ${feed['name']}: $e');
        return <NewsModel>[];
      }
    });

    final results = await Future.wait(futures);

    // Merge all articles
    final allArticles = <NewsModel>[];
    for (final articles in results) {
      allArticles.addAll(articles);
    }

    if (allArticles.isEmpty) {
      throw Exception('No articles fetched from any source for category: $category');
    }

    // Deduplicate by title similarity
    final deduplicated = _deduplicateArticles(allArticles);

    // Sort by published date (newest first)
    deduplicated.sort((a, b) {
      final dateA = DateTime.tryParse(a.publishedAt ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b.publishedAt ?? '') ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });

    return deduplicated;
  }

  // ============================================
  // PRIVATE: Deduplicate articles by title similarity
  // ============================================
  List<NewsModel> _deduplicateArticles(List<NewsModel> articles) {
    final seen = <String>{};
    final unique = <NewsModel>[];

    for (final article in articles) {
      // Create a normalized key from the title
      final titleKey = (article.title ?? '')
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .trim();

      // Skip if we've already seen a very similar title
      if (titleKey.length < 5) continue;
      final shortKey = titleKey.substring(0, (titleKey.length * 0.7).round().clamp(5, 60));

      if (!seen.any((s) => s.contains(shortKey) || shortKey.contains(s))) {
        seen.add(shortKey);
        unique.add(article);
      }
    }

    return unique;
  }

  // ============================================
  // PRIVATE: Parse RSS XML feed into NewsModel list
  // ============================================
  Future<List<NewsModel>> _parseRssFeed(
    String rssUrl, {
    String category = 'general',
    String sourceName = 'News',
  }) async {
    // Try multiple approaches to fetch the RSS feed
    String? xmlString;
    Exception? lastError;

    // Approach 1: Direct fetch with proper headers
    try {
      final response = await http
          .get(
            Uri.parse(rssUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
              'Accept': 'application/rss+xml, application/xml, text/xml, application/atom+xml, */*',
              'Accept-Language': 'en-US,en;q=0.9',
              'Connection': 'keep-alive',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 &&
          (response.body.contains('<rss') ||
           response.body.contains('<feed') ||
           response.body.contains('<channel'))) {
        xmlString = response.body;
      }
    } catch (e) {
      lastError = e is Exception ? e : Exception(e.toString());
    }

    // Approach 2: Try with a simpler User-Agent
    if (xmlString == null) {
      try {
        final response = await http
            .get(
              Uri.parse(
                'https://api.allorigins.win/raw?url=${Uri.encodeComponent(rssUrl)}',
              ),
            )
            .timeout(const Duration(seconds: 8)); // Reduced timeout for speed

        if (response.statusCode == 200 &&
            (response.body.contains('<rss') ||
             response.body.contains('<feed') ||
             response.body.contains('<channel'))) {
          xmlString = response.body;
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    // Approach 3: Try via rss2json proxy
    if (xmlString == null) {
      try {
        final proxyUrl = 'https://api.rss2json.com/v1/api.json?rss_url=${Uri.encodeComponent(rssUrl)}';
        final response = await http
            .get(Uri.parse(proxyUrl))
            .timeout(const Duration(seconds: 8)); // Reduced timeout

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          if (jsonData['status'] == 'ok' && jsonData['items'] != null) {
            return _parseRss2JsonResponse(jsonData, category: category, sourceName: sourceName);
          }
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    if (xmlString == null) {
      throw lastError ?? Exception('Failed to fetch RSS feed: $rssUrl');
    }

    // Parse XML — handle both RSS 2.0 and Atom feeds
    final document = xml.XmlDocument.parse(xmlString);
    final List<NewsModel> articles = [];

    // Try RSS 2.0 format first (most common)
    var items = document.findAllElements('item');
    if (items.isEmpty) {
      // Try Atom format
      items = document.findAllElements('entry');
    }

    for (final item in items) {
      final rssData = <String, String>{};

      // Extract title (RSS: <title>, Atom: <title>)
      final titleElement = item.findElements('title').firstOrNull;
      rssData['title'] = titleElement?.innerText ?? '';

      // Extract link (RSS: <link>, Atom: <link href="..."/>)
      final linkElement = item.findElements('link').firstOrNull;
      if (linkElement != null) {
        final href = linkElement.getAttribute('href');
        rssData['link'] = href ?? linkElement.innerText;
      }

      // Extract pubDate (RSS: <pubDate>, Atom: <published> or <updated>)
      final pubDateElement = item.findElements('pubDate').firstOrNull
          ?? item.findElements('published').firstOrNull
          ?? item.findElements('updated').firstOrNull
          ?? item.findElements('dc:date').firstOrNull;
      rssData['pubDate'] = pubDateElement?.innerText ?? '';

      // Extract description (RSS: <description>, Atom: <summary> or <content>)
      final descElement = item.findElements('description').firstOrNull
          ?? item.findElements('summary').firstOrNull
          ?? item.findElements('content').firstOrNull
          ?? item.findElements('content:encoded').firstOrNull;
      rssData['description'] = descElement?.innerText ?? '';

      // Extract source — use the provided sourceName as primary
      final sourceElement = item.findElements('source').firstOrNull
          ?? item.findElements('dc:creator').firstOrNull
          ?? item.findElements('author').firstOrNull;
      rssData['source'] = sourceElement?.innerText ?? sourceName;

      // Extract media image if present
      _extractImageFromItem(item, rssData);

      // Skip items without title
      final title = rssData['title'] ?? '';
      if (title.isEmpty || title == '[Removed]') continue;

      articles.add(NewsModel.fromRss(rssData, category: category));
    }

    return articles;
  }

  // ============================================
  // PRIVATE: Extract image URL from RSS item
  // ============================================
  void _extractImageFromItem(xml.XmlElement item, Map<String, String> rssData) {
    // Try media:content
    for (final mediaElement in item.findElements('media:content')) {
      final url = mediaElement.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        rssData['imageUrl'] = url;
        return;
      }
    }

    // Try media:thumbnail
    for (final mediaElement in item.findElements('media:thumbnail')) {
      final url = mediaElement.getAttribute('url');
      if (url != null && url.isNotEmpty) {
        rssData['imageUrl'] = url;
        return;
      }
    }

    // Try enclosure
    for (final mediaElement in item.findElements('enclosure')) {
      final url = mediaElement.getAttribute('url');
      final type = mediaElement.getAttribute('type') ?? '';
      if (url != null && (type.contains('image') || url.contains('.jpg') || url.contains('.png') || url.contains('.webp'))) {
        rssData['imageUrl'] = url;
        return;
      }
    }

    // Try to extract image from description HTML
    final description = rssData['description'] ?? '';
    if (description.contains('<img')) {
      final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false).firstMatch(description);
      if (imgMatch != null) {
        rssData['imageUrl'] = imgMatch.group(1) ?? '';
      }
    }
  }

  // ============================================
  // PRIVATE: Parse RSS feed from rss2json.com proxy response
  // ============================================
  List<NewsModel> _parseRss2JsonResponse(
    Map<String, dynamic> jsonData, {
    String category = 'general',
    String sourceName = 'News',
  }) {
    final items = jsonData['items'] as List? ?? [];
    final List<NewsModel> articles = [];

    // Get feed-level source name if available
    final feedTitle = jsonData['feed']?['title'] as String?;
    final effectiveSource = feedTitle ?? sourceName;

    for (final item in items) {
      final title = (item['title'] as String?)?.trim() ?? '';
      if (title.isEmpty || title == '[Removed]') continue;

      final rssData = <String, String>{
        'title': title,
        'link': (item['link'] as String?) ?? '',
        'pubDate': (item['pubDate'] as String?) ?? '',
        'description': (item['description'] as String?) ?? '',
        'source': (item['author'] as String?)?.isNotEmpty == true
            ? item['author'] as String
            : effectiveSource,
      };

      // Get thumbnail/enclosure image
      final thumbnail = item['thumbnail'] as String?;
      final enclosure = item['enclosure'] as Map<String, dynamic>?;
      if (thumbnail != null && thumbnail.isNotEmpty) {
        rssData['imageUrl'] = thumbnail;
      } else if (enclosure != null && enclosure['link'] != null) {
        rssData['imageUrl'] = enclosure['link'] as String;
      }

      articles.add(NewsModel.fromRss(rssData, category: category));
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
