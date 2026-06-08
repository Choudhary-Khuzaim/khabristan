const https = require('https');
const http = require('http');
const News = require('../models/News.model');
const User = require('../models/User.model');

const NEWS_API_KEY = process.env.NEWS_API_KEY || '7011d13788754be985396556f8490a2a';
const BASE_URL = 'https://newsapi.org/v2';

// ============================================
// HTTP Fetch & XML Parsing Utilities (no axios needed, no rss2json rate limits)
// ============================================
function fetchXml(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const options = {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }
    };
    client.get(url, options, (resp) => {
      if (resp.statusCode >= 300 && resp.statusCode < 400 && resp.headers.location) {
        let redirectUrl = resp.headers.location;
        if (!redirectUrl.startsWith('http')) {
          const origin = new URL(url).origin;
          redirectUrl = origin + redirectUrl;
        }
        resolve(fetchXml(redirectUrl));
      } else {
        let data = '';
        resp.on('data', (chunk) => { data += chunk; });
        resp.on('end', () => {
          resolve(data);
        });
      }
    }).on('error', (err) => reject(err));
  });
}

function decodeXmlEntities(str) {
  return str
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1');
}

function parseRssXml(xmlString) {
  const items = [];
  const itemRegExp = /<item>([\s\S]*?)<\/item>/g;
  let match;
  while ((match = itemRegExp.exec(xmlString)) !== null) {
    const itemContent = match[1];
    
    const titleMatch = itemContent.match(/<title>([\s\S]*?)<\/title>/);
    const linkMatch = itemContent.match(/<link>([\s\S]*?)<\/link>/);
    const pubDateMatch = itemContent.match(/<pubDate>([\s\S]*?)<\/pubDate>/);
    const descMatch = itemContent.match(/<description>([\s\S]*?)<\/description>/);
    const sourceMatch = itemContent.match(/<source[^>]*>([\s\S]*?)<\/source>/);
    
    let title = titleMatch ? titleMatch[1] : '';
    let link = linkMatch ? linkMatch[1] : '';
    let pubDate = pubDateMatch ? pubDateMatch[1] : '';
    let description = descMatch ? descMatch[1] : '';
    let source = sourceMatch ? sourceMatch[1] : 'Google News';
    
    items.push({
      title: decodeXmlEntities(title).trim(),
      link: decodeXmlEntities(link).trim(),
      pubDate: decodeXmlEntities(pubDate).trim(),
      description: decodeXmlEntities(description).trim(),
      source: decodeXmlEntities(source).trim(),
      author: decodeXmlEntities(source).trim()
    });
  }
  return items;
}

// ============================================
// Categories to fetch from NewsAPI
// ============================================
const CATEGORIES = ['general', 'business', 'entertainment', 'health', 'science', 'sports', 'technology'];
const COUNTRIES = ['us', 'gb'];

// ============================================
// Fetch & store top headlines for a category
// ============================================
async function fetchAndStoreCategory(category, country = 'us', systemUser) {
  try {
    let rssUrl = 'https://news.google.com/rss';
    if (category !== 'general') {
      rssUrl = `https://news.google.com/rss/headlines/section/topic/${category.toUpperCase()}`;
    }
    rssUrl += `?hl=en-${country.toUpperCase()}&gl=${country.toUpperCase()}&ceid=${country.toUpperCase()}:en`;

    const xmlData = await fetchXml(rssUrl);
    const items = parseRssXml(xmlData);

    if (items.length === 0) {
      console.log(`   ⚠️  No articles for ${category}/${country}`);
      return 0;
    }

    let savedCount = 0;

    for (const item of items) {
      // Skip articles with [Removed] title or no title
      if (!item.title || item.title === '[Removed]') continue;

      // Check if this article already exists (by title match to avoid duplicates)
      const exists = await News.findOne({
        $or: [
          { title: item.title },
          { url: item.link },
        ],
      });

      if (exists) continue;

      // Clean up description (rss feeds often contain html)
      let desc = item.description || 'No description available.';
      desc = desc.replace(/<[^>]+>/g, '').trim(); // Remove HTML tags
      
      // Extract img from description if it exists
      let imageUrl = null;
      if (item.description && item.description.includes('<img')) {
        const imgMatch = item.description.match(/<img[^>]+src="([^">]+)"/);
        if (imgMatch) imageUrl = imgMatch[1];
      }

      // Create the news article in our database
      await News.create({
        title: item.title,
        description: desc,
        url: item.link || '',
        urlToImage: imageUrl || 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800',
        category: category,
        source: item.source || 'Google News',
        author: systemUser._id,
        authorName: item.author || 'Google News',
        status: 'published',
        isFeatured: false,
        publishedAt: item.pubDate ? new Date(item.pubDate) : new Date(),
        tags: [category, country],
      });

      savedCount++;
    }

    return savedCount;
  } catch (error) {
    console.error(`   ❌ Error fetching ${category}/${country}: ${error.message}`);
    return 0;
  }
}

// ============================================
// Main: Fetch all categories for all countries
// ============================================
async function fetchAllDailyNews() {
  console.log('\n📡 ═══════════════════════════════════════');
  console.log('   KhabarIsTan — Daily News Fetch Started');
  console.log('   ═══════════════════════════════════════\n');

  // Ensure we have a system user for attributing external news
  let systemUser = await User.findOne({ username: 'newsbot' });
  if (!systemUser) {
    systemUser = await User.create({
      name: 'KhabarIsTan NewsBot',
      email: 'newsbot@khabaristan.com',
      username: 'newsbot',
      password: 'newsbot_system_2024_secure',
      role: 'admin',
      isVerified: true,
      bio: 'Automated news aggregation bot',
    });
    console.log('🤖 System NewsBot user created\n');
  }

  let totalSaved = 0;

  for (const country of COUNTRIES) {
    console.log(`\n🌍 Fetching news for country: ${country.toUpperCase()}`);
    for (const category of CATEGORIES) {
      const count = await fetchAndStoreCategory(category, country, systemUser);
      totalSaved += count;
      console.log(`   📰 ${category.padEnd(15)} → ${count} new articles`);
    }
  }

  // Mark top articles as featured (most recent 5 with images)
  const recentWithImages = await News.find({
    status: 'published',
    urlToImage: {
      $exists: true,
      $ne: '',
      $nin: ['https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800']
    },
  })
    .sort('-publishedAt')
    .limit(10);

  // Reset all featured flags first
  await News.updateMany({}, { isFeatured: false });

  // Set top 5 as featured
  for (const article of recentWithImages.slice(0, 5)) {
    article.isFeatured = true;
    await article.save();
  }

  console.log(`\n✅ Daily fetch complete: ${totalSaved} new articles saved`);
  console.log(`⭐ ${Math.min(5, recentWithImages.length)} articles marked as featured\n`);

  return totalSaved;
}

// ============================================
// Cleanup: Remove old news (older than 7 days)
// ============================================
async function cleanupOldNews() {
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  // Only delete auto-fetched news (source !== 'KhabarIsTan User')
  const result = await News.deleteMany({
    source: { $ne: 'KhabarIsTan User' },
    publishedAt: { $lt: sevenDaysAgo },
  });

  console.log(`🗑️  Cleaned up ${result.deletedCount} old articles (7+ days)`);
  return result.deletedCount;
}

module.exports = {
  fetchAllDailyNews,
  fetchAndStoreCategory,
  cleanupOldNews,
};
