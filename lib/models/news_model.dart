class NewsModel {
  final String? title;
  final String? description;
  final String? url;
  final String? urlToImage;
  final String? publishedAt;
  final String? author;
  final String? source;

  NewsModel({
    this.title,
    this.description,
    this.url,
    this.urlToImage,
    this.publishedAt,
    this.author,
    this.source,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      title: json['title'] as String?,
      description: json['description'] as String?,
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

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
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
    var articlesList = json['articles'] as List;
    List<NewsModel> articles = articlesList
        .map((article) => NewsModel.fromJson(article as Map<String, dynamic>))
        .toList();

    return NewsResponse(
      status: json['status'] as String,
      totalResults: json['totalResults'] as int,
      articles: articles,
    );
  }
}

