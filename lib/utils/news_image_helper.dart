class NewsImageHelper {
  static const Map<String, List<String>> _categoryImages = {
    'business': [
      'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800&auto=format&fit=crop', // Stock candles
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&auto=format&fit=crop', // Skyscraper business
      'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?w=800&auto=format&fit=crop', // Financial markets
      'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&auto=format&fit=crop', // Workspace charts
      'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&auto=format&fit=crop', // Corporate executive
    ],
    'entertainment': [
      'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&auto=format&fit=crop', // Concert stage
      'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&auto=format&fit=crop', // Cinema theater
      'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&auto=format&fit=crop', // Microphone studio
      'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&auto=format&fit=crop', // DJ party music
      'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop', // Red carpet lights
    ],
    'health': [
      'https://images.unsplash.com/photo-1505751172876-fa1923c5c528?w=800&auto=format&fit=crop', // Stethoscope medical
      'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=800&auto=format&fit=crop', // Doctor healthcare
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&auto=format&fit=crop', // Laboratory research
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&auto=format&fit=crop', // Healthy lifestyle
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800&auto=format&fit=crop', // Medicine pharmacy
    ],
    'science': [
      'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&auto=format&fit=crop', // Planet space technology
      'https://images.unsplash.com/photo-1507668077129-56e32842fceb?w=800&auto=format&fit=crop', // Science lab experiment
      'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&auto=format&fit=crop', // Chemistry discovery
      'https://images.unsplash.com/photo-1517976487492-5750f3195933?w=800&auto=format&fit=crop', // Rocket space launch
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop', // Digital network science
    ],
    'sports': [
      'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800&auto=format&fit=crop', // Football stadium lights
      'https://images.unsplash.com/photo-1519766304817-4f37bda74a29?w=800&auto=format&fit=crop', // Basketball court
      'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&auto=format&fit=crop', // Soccer ball pitch
      'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?w=800&auto=format&fit=crop', // Athletic runner
      'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800&auto=format&fit=crop', // Sports stadium audience
    ],
    'technology': [
      'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&auto=format&fit=crop', // Circuit microchip
      'https://images.unsplash.com/photo-1488590528505-98d2b5aba04b?w=800&auto=format&fit=crop', // Programming laptop
      'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&auto=format&fit=crop', // Cyber code matrix
      'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800&auto=format&fit=crop', // Tech setup workstation
      'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop', // Artificial intelligence
    ],
    'general': [
      'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800&auto=format&fit=crop', // Newspaper reading
      'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800&auto=format&fit=crop', // Newsroom studio
      'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=800&auto=format&fit=crop', // Newspaper press print
      'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=800&auto=format&fit=crop', // Press conference mic
      'https://images.unsplash.com/photo-1526470608268-f674ce90ebd4?w=800&auto=format&fit=crop', // Global news broadcast
    ],
  };

  /// Returns a valid image URL for a news item.
  /// If [existingUrl] is present and valid, returns [existingUrl].
  /// Otherwise, selects a high-resolution Unsplash image deterministically based on title and category.
  static String getImageUrl({
    String? existingUrl,
    String? title,
    String category = 'general',
  }) {
    if (existingUrl != null &&
        existingUrl.trim().isNotEmpty &&
        existingUrl.trim().startsWith('http')) {
      return existingUrl.trim();
    }

    final catKey = category.toLowerCase().trim();
    final images = _categoryImages[catKey] ?? _categoryImages['general']!;

    // Deterministic selection using title hashcode so the same article gets the same image consistently
    final seed = (title ?? 'khabaristan_news').hashCode.abs();
    return images[seed % images.length];
  }
}
