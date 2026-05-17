const https = require('https');
const http = require('http');
const News = require('../models/News.model');
const User = require('../models/User.model');

const NEWS_API_KEY = process.env.NEWS_API_KEY || '7011d13788754be985396556f8490a2a';
const BASE_URL = 'https://newsapi.org/v2';

// ============================================
// HTTP Fetch Utility (no axios needed)
// ============================================
function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    const options = {
      headers: {
        'User-Agent': 'KhabarIsTan-App/1.0'
      }
    };
    client.get(url, options, (resp) => {
      let data = '';
      resp.on('data', (chunk) => { data += chunk; });
      resp.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error('Failed to parse NewsAPI response')); }
      });
    }).on('error', (err) => reject(err));
  });
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
    const url = `${BASE_URL}/top-headlines?apiKey=${NEWS_API_KEY}&country=${country}&category=${category}&pageSize=20`;
    const data = await fetchUrl(url);

    if (data.status !== 'ok' || !data.articles || data.articles.length === 0) {
      console.log(`   ⚠️  No articles for ${category}/${country}`);
      return 0;
    }

    let savedCount = 0;

    for (const article of data.articles) {
      // Skip articles with [Removed] title or no title
      if (!article.title || article.title === '[Removed]') continue;
      if (!article.description || article.description === '[Removed]') continue;

      // Check if this article already exists (by title match to avoid duplicates)
      const exists = await News.findOne({
        $or: [
          { title: article.title },
          { url: article.url },
        ],
      });

      if (exists) continue;

      // Create the news article in our database
      await News.create({
        title: article.title,
        description: article.description || 'No description available.',
        url: article.url || '',
        urlToImage: article.urlToImage || 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800',
        category: category,
        source: article.source?.name || 'NewsAPI',
        author: systemUser._id,
        authorName: article.author || article.source?.name || 'NewsAPI',
        status: 'published',
        isFeatured: false,
        publishedAt: article.publishedAt ? new Date(article.publishedAt) : new Date(),
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
    urlToImage: { $ne: 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800' },
    urlToImage: { $exists: true, $ne: '' },
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
