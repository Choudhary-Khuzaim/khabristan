import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_model.dart';
import '../services/bookmarks_service.dart';
import 'glass_container.dart';

class NewsCard extends StatelessWidget {
  final NewsModel news;
  final VoidCallback onTap;
  final String? heroPrefix;

  const NewsCard({
    super.key,
    required this.news,
    required this.onTap,
    this.heroPrefix,
  });

  String _cleanSource(String? source) {
    if (source == null || source.isEmpty) return 'News';
    String cleaned = source;
    if (cleaned.contains('@')) {
      if (cleaned.contains('(') && cleaned.contains(')')) {
        final start = cleaned.indexOf('(') + 1;
        final end = cleaned.lastIndexOf(')');
        if (end > start) {
          cleaned = cleaned.substring(start, end);
        } else {
          cleaned = cleaned.split('@').first;
        }
      } else {
        cleaned = cleaned.split('@').first;
      }
    }
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    return cleaned.length > 20 ? '${cleaned.substring(0, 17)}...' : cleaned;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksService = BookmarksService();

    return AnimatedBuilder(
      animation: bookmarksService,
      builder: (context, child) {
        final isBookmarked = bookmarksService.isBookmarked(news);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: EdgeInsets.zero,
          blur: 25,
          opacity: isDark ? 0.08 : 0.4,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: Full-width Image with overlay badges
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Hero(
                  tag: '${heroPrefix ?? 'news_card'}_${news.url ?? news.title}_${news.publishedAt ?? 'now'}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: news.displayImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.newspaper_rounded,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                size: 36,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.newspaper_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 36,
                            ),
                          ),
                        ),
                        // Bottom gradient fade for readability
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.5, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  isDark
                                      ? Colors.black.withOpacity(0.5)
                                      : Colors.white.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Source badge — top left
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE94560), Color(0xFFFF8A65)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE94560).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _cleanSource(news.source),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Time badge — top right
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(news.publishedAt),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Bookmark — bottom right of image
                        Positioned(
                          bottom: 10,
                          right: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionButton(
                                icon: isBookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                isActive: isBookmarked,
                                onTap: () => bookmarksService.toggleBookmark(news),
                              ),
                              const SizedBox(width: 6),
                              _ActionButton(
                                icon: Icons.share_outlined,
                                onTap: () {
                                  if (news.url != null) {
                                    Share.share(
                                        'Check out this news: ${news.title}\n${news.url}');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                ),
              ),

              // Bottom: Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      news.title ?? 'No title available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Description preview
                    if (news.description != null &&
                        news.description!.isNotEmpty &&
                        news.description != 'Tap to read full article') ...[
                      const SizedBox(height: 8),
                      Text(
                        news.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                              height: 1.4,
                              fontSize: 12.5,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Bottom row: Read More indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Read more',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 13,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Category pill
                        if (news.category != null &&
                            news.category != 'general')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              news.category!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.4),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Mini frosted action button used on the image overlay
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.9)
              : Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: isActive
              ? const Color(0xFFE94560)
              : Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }
}
