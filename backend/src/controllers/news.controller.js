const News = require('../models/News.model');

// Helper: Format news for Flutter
function _fmt(n) {
  return {
    _id: n._id, title: n.title, description: n.description,
    url: n.url || `/news/${n.slug}`, urlToImage: n.urlToImage,
    publishedAt: n.publishedAt ? n.publishedAt.toISOString() : n.createdAt.toISOString(),
    author: n.authorName || (n.author && n.author.name) || 'Anonymous',
    source: n.source, category: n.category, slug: n.slug,
    views: n.views, likes: n.likes, isFeatured: n.isFeatured, status: n.status,
  };
}

// POST /api/v1/news — Create news
const createNews = async (req, res) => {
  try {
    const { title, description, category, urlToImage, tags } = req.body;
    const news = await News.create({
      title, description,
      category: category ? category.toLowerCase() : 'general',
      urlToImage: urlToImage || undefined,
      author: req.user.id, authorName: req.user.name,
      source: 'KhabarIsTan User', tags: tags || [],
      publishedAt: new Date(),
    });
    await news.populate('author', 'name username avatar');
    res.status(201).json({ success: true, message: 'News published successfully', data: _fmt(news) });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error creating news', error: error.message });
  }
};

// GET /api/v1/news — All published news
const getAllNews = async (req, res) => {
  try {
    const { page = 1, limit = 20, category, search, sort = '-publishedAt', featured } = req.query;
    const query = { status: 'published' };
    if (category && category !== 'all') query.category = category.toLowerCase();
    if (featured === 'true') query.isFeatured = true;
    if (search) query.$text = { $search: search };

    const total = await News.countDocuments(query);
    const news = await News.find(query)
      .populate('author', 'name username avatar')
      .sort(sort)
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    res.json({
      success: true, status: 'ok', totalResults: total,
      articles: news.map(_fmt),
      pagination: { page: parseInt(page), limit: parseInt(limit), totalPages: Math.ceil(total / parseInt(limit)), total },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching news', error: error.message });
  }
};

// GET /api/v1/news/category/:category
const getNewsByCategory = async (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const query = { status: 'published', category: req.params.category.toLowerCase() };
    const total = await News.countDocuments(query);
    const news = await News.find(query).populate('author', 'name username avatar')
      .sort('-publishedAt').skip((parseInt(page) - 1) * parseInt(limit)).limit(parseInt(limit));
    res.json({ success: true, status: 'ok', totalResults: total, articles: news.map(_fmt) });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching category news', error: error.message });
  }
};

// GET /api/v1/news/detail/:slug
const getNewsBySlug = async (req, res) => {
  try {
    const news = await News.findOne({ slug: req.params.slug }).populate('author', 'name username avatar');
    if (!news) return res.status(404).json({ success: false, message: 'News not found' });
    news.views += 1;
    await news.save();
    res.json({ success: true, data: _fmt(news) });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching news', error: error.message });
  }
};

// GET /api/v1/news/my/articles
const getMyNews = async (req, res) => {
  try {
    const news = await News.find({ author: req.user.id }).sort('-createdAt').populate('author', 'name username avatar');
    res.json({ success: true, status: 'ok', totalResults: news.length, articles: news.map(_fmt) });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching your news', error: error.message });
  }
};

// PUT /api/v1/news/:id
const updateNews = async (req, res) => {
  try {
    let news = await News.findById(req.params.id);
    if (!news) return res.status(404).json({ success: false, message: 'News not found' });
    if (news.author.toString() !== req.user.id && req.user.role !== 'admin')
      return res.status(403).json({ success: false, message: 'Not authorized' });

    const updates = {};
    ['title', 'description', 'category', 'urlToImage', 'tags'].forEach((f) => {
      if (req.body[f] !== undefined) updates[f] = req.body[f];
    });
    news = await News.findByIdAndUpdate(req.params.id, updates, { new: true, runValidators: true })
      .populate('author', 'name username avatar');
    res.json({ success: true, message: 'News updated', data: _fmt(news) });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error updating news', error: error.message });
  }
};

// DELETE /api/v1/news/:id
const deleteNews = async (req, res) => {
  try {
    const news = await News.findById(req.params.id);
    if (!news) return res.status(404).json({ success: false, message: 'News not found' });
    if (news.author.toString() !== req.user.id && req.user.role !== 'admin')
      return res.status(403).json({ success: false, message: 'Not authorized' });
    await News.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'News deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error deleting news', error: error.message });
  }
};

// POST /api/v1/news/:id/like
const toggleLike = async (req, res) => {
  try {
    const news = await News.findById(req.params.id);
    if (!news) return res.status(404).json({ success: false, message: 'News not found' });
    const userId = req.user.id;
    const isLiked = news.likedBy.includes(userId);
    if (isLiked) { news.likedBy.pull(userId); news.likes = Math.max(0, news.likes - 1); }
    else { news.likedBy.push(userId); news.likes += 1; }
    await news.save();
    res.json({ success: true, message: isLiked ? 'Unliked' : 'Liked', data: { likes: news.likes, isLiked: !isLiked } });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error toggling like', error: error.message });
  }
};

// GET /api/v1/news/top/featured
const getFeaturedNews = async (req, res) => {
  try {
    const { limit = 5 } = req.query;
    let news = await News.find({ status: 'published', isFeatured: true })
      .populate('author', 'name username avatar').sort('-publishedAt').limit(parseInt(limit));
    if (news.length === 0) {
      news = await News.find({ status: 'published' })
        .populate('author', 'name username avatar').sort('-views -publishedAt').limit(parseInt(limit));
    }
    res.json({ success: true, status: 'ok', totalResults: news.length, articles: news.map(_fmt) });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching featured', error: error.message });
  }
};

module.exports = { createNews, getAllNews, getNewsByCategory, getNewsBySlug, getMyNews, updateNews, deleteNews, toggleLike, getFeaturedNews };
