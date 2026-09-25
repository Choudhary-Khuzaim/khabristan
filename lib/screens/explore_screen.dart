import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/news_service.dart';
import '../widgets/glass_background.dart';
import '../widgets/glass_container.dart';
import 'source_news_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final List<Map<String, String>> _sources;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  void _loadSources() {
    // Pre-compute sources list once to avoid repeated computation on every build
    _sources = NewsService().getAllSources();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
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
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: AnimationLimiter(
                    child: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final source = _sources[index];
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
                        childCount: _sources.length,
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
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
      return Uri.parse(url).host.replaceAll('www.', '');
    } catch (_) {
      return '';
    }
  }

  /// Get the best logo URL using multiple favicon/logo APIs
  /// Clearbit is highest quality, with Google favicons and icon.horse as fallbacks
  List<String> _getLogoUrls(String domain) {
    if (domain.isEmpty) return [];
    return [
      'https://logo.clearbit.com/$domain', // Best quality
      'https://www.google.com/s2/favicons?domain=$domain&sz=128', // Google fallback
      'https://icon.horse/icon/$domain', // Secondary fallback
    ];
  }

  @override
  Widget build(BuildContext context) {
    final domain = _getDomain(url);
    final logoUrls = _getLogoUrls(domain);

    return GlassContainer(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: logoUrls.isNotEmpty
                  ? _LogoWithFallback(logoUrls: logoUrls)
                  : Icon(
                      Icons.newspaper_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.3),
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
    );
  }
}

/// Tries multiple logo URLs in order, falling back to next on error
class _LogoWithFallback extends StatefulWidget {
  final List<String> logoUrls;

  const _LogoWithFallback({required this.logoUrls});

  @override
  State<_LogoWithFallback> createState() => _LogoWithFallbackState();
}

class _LogoWithFallbackState extends State<_LogoWithFallback> {
  int _currentUrlIndex = 0;
  bool _hasFailed = false;

  @override
  Widget build(BuildContext context) {
    if (_hasFailed || _currentUrlIndex >= widget.logoUrls.length) {
      // All URLs failed — show fallback icon
      return Icon(
        Icons.newspaper_rounded,
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.logoUrls[_currentUrlIndex],
      fit: BoxFit.contain,
      placeholder: (context, url) => Icon(
        Icons.newspaper_rounded,
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
      ),
      errorWidget: (context, url, error) {
        // Try next URL in the fallback chain
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final nextIndex = _currentUrlIndex + 1;
            setState(() {
              _currentUrlIndex = nextIndex;
              if (nextIndex >= widget.logoUrls.length) {
                _hasFailed = true;
              }
            });
          }
        });
        return Icon(
          Icons.newspaper_rounded,
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
        );
      },
    );
  }
}
