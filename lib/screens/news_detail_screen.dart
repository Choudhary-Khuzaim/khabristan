import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

import 'package:share_plus/share_plus.dart';
import '../models/news_model.dart';
import 'article_view_screen.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsModel news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late FlutterTts _flutterTts;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isPlaying = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });

    _flutterTts.setCancelHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });

    _flutterTts.setErrorHandler((msg) {
       if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _speak() async {
    if (_isPlaying) {
      await _flutterTts.stop();
    } else {
      final textToSpeak = "${widget.news.title}. ${widget.news.description ?? ''}";
      if (textToSpeak.trim().isNotEmpty) {
        await _flutterTts.speak(textToSpeak);
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy • hh:mm a').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _openUrl(BuildContext context, String? url) {
    if (url != null && url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleViewScreen(
            articleUrl: url,
            title: widget.news.title ?? 'News Article',
          ),
        ),
      );
    }
  }

  Future<void> _shareNews() async {
    final text = '${widget.news.title}\n\n${widget.news.description ?? ''}\n\n${widget.news.url ?? ''}';
    await Share.share(text, subject: widget.news.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _speak,
        icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.volume_up_rounded),
        label: Text(_isPlaying ? 'Stop Listening' : 'Listen to News'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.news.urlToImage != null && widget.news.urlToImage!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.news.urlToImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue[400]!,
                                  Colors.blue[300]!,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue[400]!,
                                  Colors.blue[300]!,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blue[400]!,
                                Colors.blue[300]!,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.article,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded),
                  color: Colors.white,
                  onPressed: _shareNews,
                  tooltip: 'Share',
                ),
              ),
              if (widget.news.url != null)
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.open_in_new_rounded),
                    color: Colors.white,
                    onPressed: () => _openUrl(context, widget.news.url),
                    tooltip: 'Open in browser',
                  ),
                ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source and Date
                    Row(
                      children: [
                        if (widget.news.source != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.news.source!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(widget.news.publishedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      widget.news.title ?? 'No title available',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Author
                    if (widget.news.author != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Author',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    widget.news.author!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 28),
                    // Divider
                    Divider(
                      color: Colors.grey[300],
                      thickness: 1,
                    ),
                    const SizedBox(height: 28),
                    // Description
                    if (widget.news.description != null && widget.news.description!.isNotEmpty)
                      Text(
                        widget.news.description!,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[800],
                          height: 1.7,
                          letterSpacing: 0.2,
                        ),
                      ),
                    const SizedBox(height: 40),
                    // Read Full Article Button
                    if (widget.news.url != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openUrl(context, widget.news.url),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text(
                            'Read Full Article',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Share Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _shareNews,
                        icon: const Icon(Icons.share_rounded),
                        label: const Text(
                          'Share Article',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60), // Space for FAB
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
