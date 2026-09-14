class NewsModel {
  final String? title;
  final String? description;
  final String? content;
  final String? url;
  final String? urlToImage;
  final String? publishedAt;
  final String? author;
  final String? source;

  NewsModel({
    this.title,
    this.description,
    this.content,
    this.url,
    this.urlToImage,
    this.publishedAt,
    this.author,
    this.source,
  });

  /// Parse from backend JSON response (existing format)
  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      title: json['title'] as String?,
      description: json['description'] as String?,
      content: json['content'] as String?,
      url: json['url'] as String?,
      urlToImage: json['urlToImage'] as String?,
      publishedAt: json['publishedAt'] as String?,
      author: json['author'] as String?,
      source: json['source'] != null
          ? (json['source'] is Map
              ? json['source']['name'] as String?
              : json['source'] as String?)
          : null,
    );
  }

  /// Parse from Google News RSS item data
  factory NewsModel.fromRss(Map<String, String> rssItem) {
    // Extract image from description HTML if present
    String? imageUrl;
    final description = rssItem['description'] ?? '';
    final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(description);
    if (imgMatch != null) {
      imageUrl = imgMatch.group(1);
    }

    // Clean HTML tags from description
    final cleanDescription = description
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();

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

    return NewsModel(
      title: rssItem['title']?.trim(),
      description: cleanDescription.isNotEmpty
          ? cleanDescription
          : 'Tap to read full article',
      content: cleanDescription,
      url: rssItem['link']?.trim(),
      urlToImage: imageUrl,
      publishedAt: publishedAt ?? DateTime.now().toIso8601String(),
      author: rssItem['source']?.trim() ?? 'Google News',
      source: rssItem['source']?.trim() ?? 'Google News',
    );
  }

  /// Parse RSS date format (e.g. "Sat, 14 Sep 2026 10:30:00 GMT")
  static String _parseRssDate(String dateStr) {
    try {
      // RFC 2822 date format used in RSS
      final months = {
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
        'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
        'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
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
