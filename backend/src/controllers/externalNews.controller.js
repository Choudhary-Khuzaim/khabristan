const https = require('https');
const http = require('http');
const News = require('../models/News.model');
const { fetchAllDailyNews, cleanupOldNews } = require('../services/newsFetcher.service');

const NEWS_API_KEY = process.env.NEWS_API_KEY || '7011d13788754be985396556f8490a2a';
const BASE_URL = 'https://newsapi.org/v2';

function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    const client = url.startsWith('https') ? https : http;
    client.get(url, (resp) => {
      let data = '';
      resp.on('data', (chunk) => { data += chunk; });
      resp.on('end', () => {
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(new Error('Failed to parse response')); }
      });
    }).on('error', reject);
  });
}

// ============================================
// @desc    Proxy: Top headlines from NewsAPI (live)
// @route   GET /api/v1/external-news/top-headlines
// @access  Public
// ============================================
const getTopHeadlines = async (req, res) => {
  try {
    const { category = 'general', country = 'us', q, page = 1, pageSize = 20 } = req.query;
    let url = `${BASE_URL}/top-headlines?apiKey=${NEWS_API_KEY}&country=${country}&category=${category}&page=${page}&pageSize=${pageSize}`;
    if (q) url += `&q=${encodeURIComponent(q)}`;

    const data = await fetchUrl(url);
    res.json({
      success: true,
      status: data.status,
      totalResults: data.totalResults || 0,
      articles: (data.articles || []).map(_formatArticle),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching headlines', error: error.message });
  }
};

// ============================================
// @desc    Proxy: Search everything from NewsAPI (live)
// @route   GET /api/v1/external-news/everything
// @access  Public
// ============================================
const getEverything = async (req, res) => {
  try {
    const { q, page = 1, pageSize = 20, sortBy = 'publishedAt' } = req.query;
    if (!q) return res.status(400).json({ success: false, message: 'Query parameter "q" is required' });

    const url = `${BASE_URL}/everything?q=${encodeURIComponent(q)}&apiKey=${NEWS_API_KEY}&page=${page}&pageSize=${pageSize}&sortBy=${sortBy}`;
    const data = await fetchUrl(url);
    res.json({
      success: true,
      status: data.status,
      totalResults: data.totalResults || 0,
      articles: (data.articles || []).map(_formatArticle),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error searching news', error: error.message });
  }
};

// ============================================
// @desc    Get daily news from local DB (cached)
//          This is the PRIMARY endpoint for the Flutter app
// @route   GET /api/v1/external-news/daily
// @access  Public
// ============================================
const getDailyNews = async (req, res) => {
  try {
    const { category = 'all', page = 1, limit = 20, featured } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);

    const query = { status: 'published' };

    // Filter by category
    if (category && category !== 'all') {
      query.category = category.toLowerCase();
    }

    // Filter by featured
    if (featured === 'true') {
      query.isFeatured = true;
    }

    // Only show articles from last 3 days for "daily" news feel
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3);
    query.publishedAt = { $gte: threeDaysAgo };

    const total = await News.countDocuments(query);
    const articles = await News.find(query)
      .sort('-publishedAt')
      .skip((pageNum - 1) * limitNum)
      .limit(limitNum)
      .lean();

    res.json({
      success: true,
      status: 'ok',
      totalResults: total,
      articles: articles.map(_formatDbArticle),
      pagination: {
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum),
        total,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching daily news', error: error.message });
  }
};

// ============================================
// @desc    Get featured/breaking news from DB
// @route   GET /api/v1/external-news/featured
// @access  Public
// ============================================
const getFeaturedDailyNews = async (req, res) => {
  try {
    const { limit = 5 } = req.query;

    let articles = await News.find({
      status: 'published',
      isFeatured: true,
    })
      .sort('-publishedAt')
      .limit(parseInt(limit))
      .lean();

    // Fallback: if no featured, get most viewed recent articles
    if (articles.length === 0) {
      const oneDayAgo = new Date();
      oneDayAgo.setDate(oneDayAgo.getDate() - 1);
      articles = await News.find({
        status: 'published',
        publishedAt: { $gte: oneDayAgo },
      })
        .sort('-views -publishedAt')
        .limit(parseInt(limit))
        .lean();
    }

    // Final fallback: just get newest
    if (articles.length === 0) {
      articles = await News.find({ status: 'published' })
        .sort('-publishedAt')
        .limit(parseInt(limit))
        .lean();
    }

    res.json({
      success: true,
      status: 'ok',
      totalResults: articles.length,
      articles: articles.map(_formatDbArticle),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching featured news', error: error.message });
  }
};

// ============================================
// @desc    Search news from local DB
// @route   GET /api/v1/external-news/search
// @access  Public
// ============================================
const searchDailyNews = async (req, res) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;
    if (!q) return res.status(400).json({ success: false, message: 'Query parameter "q" is required' });

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);

    // Use text search if available, otherwise regex
    let query;
    try {
      query = { $text: { $search: q }, status: 'published' };
      await News.countDocuments(query); // Test if text index works
    } catch {
      // Fallback to regex search
      const regex = new RegExp(q, 'i');
      query = {
        status: 'published',
        $or: [
          { title: { $regex: regex } },
          { description: { $regex: regex } },
        ],
      };
    }

    const total = await News.countDocuments(query);
    const articles = await News.find(query)
      .sort('-publishedAt')
      .skip((pageNum - 1) * limitNum)
      .limit(limitNum)
      .lean();

    res.json({
      success: true,
      status: 'ok',
      totalResults: total,
      articles: articles.map(_formatDbArticle),
      pagination: {
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum),
        total,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error searching news', error: error.message });
  }
};

// ============================================
// @desc    Manually trigger news fetch (admin only)
// @route   POST /api/v1/external-news/fetch-now
// @access  Private/Admin
// ============================================
const triggerFetchNow = async (req, res) => {
  try {
    const count = await fetchAllDailyNews();
    res.json({
      success: true,
      message: `Manual fetch complete. ${count} new articles added.`,
      articlesAdded: count,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error triggering fetch', error: error.message });
  }
};

// ============================================
// @desc    Manually trigger cleanup (admin only)
// @route   POST /api/v1/external-news/cleanup
// @access  Private/Admin
// ============================================
const triggerCleanup = async (req, res) => {
  try {
    const count = await cleanupOldNews();
    res.json({
      success: true,
      message: `Cleanup complete. ${count} old articles removed.`,
      articlesRemoved: count,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error triggering cleanup', error: error.message });
  }
};

// ============================================
// @desc    Get news stats (for admin dashboard)
// @route   GET /api/v1/external-news/stats
// @access  Public
// ============================================
const getNewsStats = async (req, res) => {
  try {
    const total = await News.countDocuments({ status: 'published' });
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayCount = await News.countDocuments({ status: 'published', publishedAt: { $gte: today } });

    const categories = ['general', 'business', 'entertainment', 'health', 'science', 'sports', 'technology'];
    const categoryCounts = {};
    for (const cat of categories) {
      categoryCounts[cat] = await News.countDocuments({ status: 'published', category: cat });
    }

    res.json({
      success: true,
      data: {
        totalArticles: total,
        todayArticles: todayCount,
        categoryCounts,
        lastUpdated: new Date().toISOString(),
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching stats', error: error.message });
  }
};

// ============================================
// Format helpers
// ============================================
function _formatArticle(article) {
  return {
    title: article.title,
    description: article.description,
    url: article.url,
    urlToImage: article.urlToImage,
    publishedAt: article.publishedAt,
    author: article.author,
    source: article.source ? article.source.name : null,
  };
}

function _formatDbArticle(article) {
  return {
    _id: article._id,
    title: article.title,
    description: article.description,
    url: article.url || '',
    urlToImage: article.urlToImage,
    publishedAt: article.publishedAt ? new Date(article.publishedAt).toISOString() : new Date().toISOString(),
    author: article.authorName || 'NewsAPI',
    source: article.source || 'NewsAPI',
    category: article.category,
    views: article.views || 0,
    likes: article.likes || 0,
    isFeatured: article.isFeatured || false,
    slug: article.slug,
  };
}

module.exports = {
  getTopHeadlines,
  getEverything,
  getDailyNews,
  getFeaturedDailyNews,
  searchDailyNews,
  triggerFetchNow,
  triggerCleanup,
  getNewsStats,
};
