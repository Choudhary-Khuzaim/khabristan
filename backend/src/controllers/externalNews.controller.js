const https = require('https');
const http = require('http');
const News = require('../models/News.model');
const { fetchAllDailyNews, cleanupOldNews } = require('../services/newsFetcher.service');

const NEWS_API_KEY = process.env.NEWS_API_KEY || '7011d13788754be985396556f8490a2a';
const BASE_URL = 'https://newsapi.org/v2';

// Format helper
function _fmt(n) {
  return {
    _id: n._id, title: n.title, description: n.description,
    url: n.url || `/news/${n.slug}`, urlToImage: n.urlToImage,
    publishedAt: n.publishedAt ? new Date(n.publishedAt).toISOString() : new Date(n.createdAt).toISOString(),
    author: n.authorName || (n.author && n.author.name) || 'Anonymous',
    source: n.source, category: n.category, slug: n.slug,
    views: n.views, likes: n.likes, isFeatured: n.isFeatured, status: n.status,
  };
}

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
    const { category = 'general', country = 'us', page = 1, pageSize = 20 } = req.query;
    const url = `https://saurav.tech/NewsAPI/top-headlines/category/${category}/${country}.json`;
    const data = await fetchUrl(url);
    res.json({
      success: true,
      status: data.status,
      totalResults: data.totalResults || 0,
      articles: (data.articles || []).map(_formatProxyArticle),
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
      articles: (data.articles || []).map(_formatProxyArticle),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error searching news', error: error.message });
  }
};

// ============================================
// @desc    Get daily news (Cached in MongoDB)
// @route   GET /api/v1/external-news/daily
// @access  Public
// ============================================
const getDailyNews = async (req, res) => {
  try {
    let { category = 'all', page = 1, limit = 20 } = req.query;
    const query = { status: 'published' };
    
    if (category !== 'all') {
      query.category = category.toLowerCase();
    }

    const total = await News.countDocuments(query);
    const news = await News.find(query)
      .sort('-publishedAt')
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    res.json({
      success: true,
      status: 'ok',
      totalResults: total,
      articles: news.map(_fmt),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit)),
        total,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching daily news', error: error.message });
  }
};

// ============================================
// @desc    Get featured/breaking news (Cached in MongoDB)
// @route   GET /api/v1/external-news/featured
// @access  Public
// ============================================
const getFeaturedDailyNews = async (req, res) => {
  try {
    const { limit = 5 } = req.query;
    let news = await News.find({ status: 'published', isFeatured: true })
      .sort('-publishedAt')
      .limit(parseInt(limit));
      
    if (news.length === 0) {
      news = await News.find({ status: 'published' })
        .sort('-views -publishedAt')
        .limit(parseInt(limit));
    }
    
    res.json({
      success: true,
      status: 'ok',
      totalResults: news.length,
      articles: news.map(_fmt),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching featured news', error: error.message });
  }
};

// ============================================
// @desc    Search news (Cached in MongoDB)
// @route   GET /api/v1/external-news/search
// @access  Public
// ============================================
const searchDailyNews = async (req, res) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;
    if (!q) return res.status(400).json({ success: false, message: 'Query parameter "q" is required' });

    // Use regex search
    const query = {
      status: 'published',
      $or: [
        { title: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } },
      ],
    };

    const total = await News.countDocuments(query);
    const news = await News.find(query)
      .sort('-publishedAt')
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    res.json({
      success: true,
      status: 'ok',
      totalResults: total,
      articles: news.map(_fmt),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit)),
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
    res.json({ success: true, message: 'Manual fetch complete.', articlesAdded: count });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching news', error: error.message });
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
    res.json({ success: true, message: 'Cleanup complete.', articlesRemoved: count });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error cleaning up', error: error.message });
  }
};

// ============================================
// @desc    Get news stats (for admin dashboard)
// @route   GET /api/v1/external-news/stats
// @access  Public
// ============================================
const getNewsStats = async (req, res) => {
  try {
    const totalArticles = await News.countDocuments({ status: 'published' });
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayArticles = await News.countDocuments({ status: 'published', createdAt: { $gte: today } });

    res.json({
      success: true,
      data: {
        totalArticles,
        todayArticles,
        lastUpdated: new Date().toISOString(),
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error getting stats', error: error.message });
  }
};

// ============================================
// Format proxy article helper
// ============================================
function _formatProxyArticle(article) {
  return {
    _id: Math.random().toString(36).substring(7),
    title: article.title || 'No Title',
    description: article.description || 'No Description',
    url: article.url || '',
    urlToImage: article.urlToImage,
    publishedAt: article.publishedAt ? new Date(article.publishedAt).toISOString() : new Date().toISOString(),
    author: article.author || 'NewsAPI',
    source: article.source ? article.source.name : 'NewsAPI',
    category: 'general',
    views: 0,
    likes: 0,
    isFeatured: false,
    slug: (article.title || '').toLowerCase().replace(/[^a-z0-9]+/g, '-') + '-' + Math.random().toString(36).substring(2, 8),
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
