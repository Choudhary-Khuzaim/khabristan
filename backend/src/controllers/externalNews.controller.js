const https = require('https');
const http = require('http');
const NEWS_API_KEY = process.env.NEWS_API_KEY || '7011d13788754be985396556f8490a2a';
const BASE_URL = 'https://newsapi.org/v2';

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
// @desc    Get daily news (Proxied from NewsAPI)
// @route   GET /api/v1/external-news/daily
// @access  Public
// ============================================
const getDailyNews = async (req, res) => {
  try {
    let { category = 'all', page = 1, limit = 20 } = req.query;
    if (category === 'all') category = 'general';
    
    let url = `${BASE_URL}/top-headlines?apiKey=${NEWS_API_KEY}&country=us&category=${category}&page=${page}&pageSize=${limit}`;
    const data = await fetchUrl(url);
    res.json({
      success: true,
      status: 'ok',
      totalResults: data.totalResults || 0,
      articles: (data.articles || []).map(_formatArticle),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil((data.totalResults || 0) / parseInt(limit)),
        total: data.totalResults || 0,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching daily news', error: error.message });
  }
};

// ============================================
// @desc    Get featured/breaking news (Proxied from NewsAPI)
// @route   GET /api/v1/external-news/featured
// @access  Public
// ============================================
const getFeaturedDailyNews = async (req, res) => {
  try {
    const { limit = 5 } = req.query;
    let url = `${BASE_URL}/top-headlines?apiKey=${NEWS_API_KEY}&country=us&pageSize=${limit}`;
    const data = await fetchUrl(url);
    res.json({
      success: true,
      status: 'ok',
      totalResults: data.totalResults || 0,
      articles: (data.articles || []).map(_formatArticle),
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching featured news', error: error.message });
  }
};

// ============================================
// @desc    Search news (Proxied from NewsAPI)
// @route   GET /api/v1/external-news/search
// @access  Public
// ============================================
const searchDailyNews = async (req, res) => {
  try {
    const { q, page = 1, limit = 20 } = req.query;
    if (!q) return res.status(400).json({ success: false, message: 'Query parameter "q" is required' });

    const url = `${BASE_URL}/everything?q=${encodeURIComponent(q)}&apiKey=${NEWS_API_KEY}&page=${page}&pageSize=${limit}&sortBy=publishedAt`;
    const data = await fetchUrl(url);

    res.json({
      success: true,
      status: 'ok',
      totalResults: data.totalResults || 0,
      articles: (data.articles || []).map(_formatArticle),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil((data.totalResults || 0) / parseInt(limit)),
        total: data.totalResults || 0,
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
  res.json({ success: true, message: 'Manual fetch complete (Database disabled).', articlesAdded: 0 });
};

// ============================================
// @desc    Manually trigger cleanup (admin only)
// @route   POST /api/v1/external-news/cleanup
// @access  Private/Admin
// ============================================
const triggerCleanup = async (req, res) => {
  res.json({ success: true, message: 'Cleanup complete (Database disabled).', articlesRemoved: 0 });
};

// ============================================
// @desc    Get news stats (for admin dashboard)
// @route   GET /api/v1/external-news/stats
// @access  Public
// ============================================
const getNewsStats = async (req, res) => {
  res.json({
    success: true,
    data: {
      totalArticles: 0,
      todayArticles: 0,
      categoryCounts: {},
      lastUpdated: new Date().toISOString(),
    },
  });
};

// ============================================
// Format helpers
// ============================================
function _formatArticle(article) {
  // Return the format the flutter app expects
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
