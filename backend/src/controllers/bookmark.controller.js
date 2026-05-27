const Bookmark = require('../models/Bookmark.model');

// @desc    Get user's bookmarks
// @route   GET /api/v1/bookmarks
// @access  Private
const getBookmarks = async (req, res) => {
  try {
    const bookmarks = await Bookmark.find({ user: req.user.id })
      .populate('news', 'title description urlToImage publishedAt source')
      .sort('-createdAt');

    const articles = bookmarks.map((b) => {
      if (b.type === 'internal') {
        if (!b.news) return null;
        return {
          _id: b._id,
          type: 'internal',
          newsId: b.news._id,
          title: b.news.title,
          description: b.news.description,
          urlToImage: b.news.urlToImage,
          publishedAt: b.news.publishedAt,
          source: b.news.source,
        };
      }
      return {
        _id: b._id,
        type: 'external',
        ...(b.externalArticle && typeof b.externalArticle.toObject === 'function'
          ? b.externalArticle.toObject()
          : (b.externalArticle || {})),
      };
    }).filter(Boolean);

    res.json({ success: true, totalResults: articles.length, articles });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching bookmarks', error: error.message });
  }
};

// @desc    Add bookmark
// @route   POST /api/v1/bookmarks
// @access  Private
const addBookmark = async (req, res) => {
  try {
    const { type, newsId, title, description, url, urlToImage, publishedAt, author, source } = req.body;

    let bookmark;
    if (type === 'internal' && newsId) {
      const exists = await Bookmark.findOne({ user: req.user.id, news: newsId });
      if (exists) return res.status(400).json({ success: false, message: 'Already bookmarked' });
      bookmark = await Bookmark.create({ user: req.user.id, news: newsId, type: 'internal' });
    } else {
      const exists = await Bookmark.findOne({ user: req.user.id, 'externalArticle.url': url });
      if (exists) return res.status(400).json({ success: false, message: 'Already bookmarked' });
      bookmark = await Bookmark.create({
        user: req.user.id,
        type: 'external',
        externalArticle: { title, description, url, urlToImage, publishedAt, author, source },
      });
    }

    res.status(201).json({ success: true, message: 'Bookmarked successfully', data: bookmark });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error adding bookmark', error: error.message });
  }
};

// @desc    Remove bookmark
// @route   DELETE /api/v1/bookmarks/:id
// @access  Private
const removeBookmark = async (req, res) => {
  try {
    const bookmark = await Bookmark.findOne({ _id: req.params.id, user: req.user.id });
    if (!bookmark) return res.status(404).json({ success: false, message: 'Bookmark not found' });
    await Bookmark.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Bookmark removed' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error removing bookmark', error: error.message });
  }
};

// @desc    Check if article is bookmarked
// @route   POST /api/v1/bookmarks/check
// @access  Private
const checkBookmark = async (req, res) => {
  try {
    const { newsId, url } = req.body;
    let bookmark;
    if (newsId) {
      bookmark = await Bookmark.findOne({ user: req.user.id, news: newsId });
    } else if (url) {
      bookmark = await Bookmark.findOne({ user: req.user.id, 'externalArticle.url': url });
    }
    res.json({ success: true, isBookmarked: !!bookmark, bookmarkId: bookmark?._id || null });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error checking bookmark', error: error.message });
  }
};

module.exports = { getBookmarks, addBookmark, removeBookmark, checkBookmark };
