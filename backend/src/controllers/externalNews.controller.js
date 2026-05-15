const https = require('https');
const http = require('http');

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

// @desc    Proxy: Top headlines
// @route   GET /api/v1/external-news/top-headlines
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

// @desc    Proxy: Search everything
// @route   GET /api/v1/external-news/everything
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

module.exports = { getTopHeadlines, getEverything };
