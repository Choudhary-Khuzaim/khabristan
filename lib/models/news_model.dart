import '../utils/news_image_helper.dart';

class NewsModel {
  final String? title;
  final String? description;
  final String? content;
  final String? url;
  final String? urlToImage;
  final String? publishedAt;
  final String? author;
  final String? source;
  final String? category;

  NewsModel({
    this.title,
    this.description,
    this.content,
    this.url,
    this.urlToImage,
    this.publishedAt,
    this.author,
    this.source,
    this.category,
  });

  /// Guaranteed non-null image URL for UI rendering
  String get displayImageUrl {
    return NewsImageHelper.getImageUrl(
      existingUrl: urlToImage,
      title: title,
      category: category ?? 'general',
    );
  }

  /// Parse from backend JSON response (existing format)
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String?;
    final rawUrlToImage = json['urlToImage'] as String?;
    final category = json['category'] as String?;

    return NewsModel(
      title: title,
      description: json['description'] as String?,
      content: json['content'] as String?,
      url: json['url'] as String?,
      urlToImage: NewsImageHelper.getImageUrl(
        existingUrl: rawUrlToImage,
        title: title,
        category: category ?? 'general',
      ),
      publishedAt: json['publishedAt'] as String?,
      author: json['author'] as String?,
      source: json['source'] != null
          ? (json['source'] is Map
              ? json['source']['name'] as String?
              : json['source'] as String?)
          : null,
      category: category,
    );
  }

  /// Parse from RSS feed item data
  factory NewsModel.fromRss(Map<String, String> rssItem,
      {String category = 'general'}) {
    // Extract image from description HTML if present or media tags
    String? imageUrl = rssItem['imageUrl'];
    if (imageUrl == null || imageUrl.isEmpty) {
      final description = rssItem['description'] ?? '';
      final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false)
          .firstMatch(description);
      if (imgMatch != null) {
        imageUrl = imgMatch.group(1);
      }
    }

    // Thoroughly clean HTML/code artifacts from description
    String rawDesc = rssItem['description'] ?? '';

    // 1. Remove CDATA wrappers
    rawDesc =
        rawDesc.replaceAll(RegExp(r'<!\[CDATA\[', caseSensitive: false), '');
    rawDesc = rawDesc.replaceAll(RegExp(r'\]\]>', caseSensitive: false), '');

    // 2. Remove script and style blocks (content + tags)
    rawDesc = rawDesc.replaceAll(
        RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '');
    rawDesc = rawDesc.replaceAll(
        RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '');

    // 3. Remove HTML comments
    rawDesc = rawDesc.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');

    // 4. Remove all HTML tags
    rawDesc = rawDesc.replaceAll(RegExp(r'<[^>]+>'), '');

    // 5. Decode common HTML entities
    rawDesc = rawDesc
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '…');

    // 6. Remove JavaScript/code patterns that survived
    rawDesc = rawDesc.replaceAll(
        RegExp(r'if\s*\([^)]*\)\s*\{[^}]*\}', caseSensitive: false), '');
    rawDesc = rawDesc.replaceAll(
        RegExp(r'else\s*\{[^}]*\}', caseSensitive: false), '');
    rawDesc = rawDesc.replaceAll(
        RegExp(r'function\s*\([^)]*\)\s*\{[^}]*\}', caseSensitive: false), '');
    rawDesc = rawDesc.replaceAll(RegExp(r'var\s+\w+\s*=\s*[^;]+;'), '');
    rawDesc = rawDesc.replaceAll(RegExp(r'document\.\w+'), '');
    rawDesc = rawDesc.replaceAll(RegExp(r'window\.\w+'), '');
    rawDesc = rawDesc.replaceAll(RegExp(r'\{[^}]{0,50}\}'), '');

    // 7. Collapse excessive whitespace
    rawDesc = rawDesc.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 8. Validate: if it still looks like code, discard
    final looksLikeCode = rawDesc.contains('function') ||
        rawDesc.contains('var ') ||
        rawDesc.contains('===') ||
        rawDesc.contains('!==') ||
        (rawDesc.contains('if(') || rawDesc.contains('if (')) &&
            rawDesc.contains('{') ||
        rawDesc.startsWith('//') ||
        rawDesc.startsWith('/*');

    final cleanDescription =
        (!looksLikeCode && rawDesc.length >= 10) ? rawDesc : '';

    // Parse published date
    String? publishedAt;
    final pubDate = rssItem['pubDate'];
    if (pubDate != null && pubDate.isNotEmpty) {
      try {
        publishedAt = DateTime.parse(
          _parseRssDate(pubDate),
        ).toIso8601String();
      } catch (_) {
        publishedAt = DateTime.now().toIso8601String();
      }
    }

    final title = rssItem['title']?.trim();
    final finalImageUrl = NewsImageHelper.getImageUrl(
      existingUrl: imageUrl,
      title: title,
      category: category,
    );

    return NewsModel(
      title: title,
      description: cleanDescription.isNotEmpty
          ? cleanDescription
          : 'Tap to read full article',
      content: cleanDescription,
      url: rssItem['link']?.trim(),
      urlToImage: finalImageUrl,
      publishedAt: publishedAt ?? DateTime.now().toIso8601String(),
      author: rssItem['source']?.trim() ?? 'News',
      source: rssItem['source']?.trim() ?? 'News',
      category: category,
    );
  }

  /// Parse RSS date format (e.g. "Sat, 14 Sep 2026 10:30:00 GMT")
  static String _parseRssDate(String dateStr) {
    try {
      // RFC 2822 date format used in RSS
      final months = {
        'Jan': '01',
        'Feb': '02',
        'Mar': '03',
        'Apr': '04',
        'May': '05',
        'Jun': '06',
        'Jul': '07',
        'Aug': '08',
        'Sep': '09',
        'Oct': '10',
        'Nov': '11',
        'Dec': '12',
      };

      // "Sat, 14 Sep 2026 10:30:00 GMT"
      final parts = dateStr.replaceAll(',', '').trim().split(RegExp(r'\s+'));
      if (parts.length >= 5) {
        final day = parts[1].padLeft(2, '0');
        final month = months[parts[2]] ?? '01';
        final year = parts[3];
        final time = parts[4];
        return '$year-$month-${day}T${time}Z';
      }
    } catch (_) {}
    return DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt,
      'author': author,
      'source': source,
      'category': category,
    };
  }
}

class NewsResponse {
  final String status;
  final int totalResults;
  final List<NewsModel> articles;

  NewsResponse({
    required this.status,
    required this.totalResults,
    required this.articles,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    var articlesList = json['articles'] as List? ?? [];
    List<NewsModel> articlesArray = articlesList
        .whereType<Map<String, dynamic>>()
        .map((article) => NewsModel.fromJson(article))
        .toList();

    return NewsResponse(
      status: json['status'] as String? ?? 'error',
      totalResults: json['totalResults'] as int? ?? 0,
      articles: articlesArray,
    );
  }
}
