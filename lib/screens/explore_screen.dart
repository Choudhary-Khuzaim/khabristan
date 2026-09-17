import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/news_service.dart';
import 'source_news_screen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Sources',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discover news from your favorite channels',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: AnimationLimiter(
                child: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final source = NewsService().getAllSources()[index];
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        columnCount: 2,
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: _SourceCard(
                              name: source['name']!,
                              url: source['url']!,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SourceNewsScreen(
                                      sourceName: source['name']!,
                                      sourceUrl: source['url']!,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: NewsService().getAllSources().length,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final String name;
  final String url;
  final VoidCallback onTap;

  const _SourceCard({
    required this.name,
    required this.url,
    required this.onTap,
  });

  String _getDomain(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final domain = _getDomain(url);
    final logoUrl = domain.isNotEmpty
        ? 'https://www.google.com/s2/favicons?domain=$domain&sz=128'
        : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: logoUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Icon(
                          Icons.newspaper_rounded,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.newspaper_rounded,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      )
                    : Icon(
                        Icons.newspaper_rounded,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
