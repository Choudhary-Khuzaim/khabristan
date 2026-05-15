const router = require('express').Router();
const {
  createNews, getAllNews, getNewsByCategory, getNewsBySlug,
  getMyNews, updateNews, deleteNews, toggleLike, getFeaturedNews,
} = require('../controllers/news.controller');
const { protect } = require('../middleware/auth.middleware');
const { newsRules } = require('../middleware/validate.middleware');

// Public routes
router.get('/', getAllNews);
router.get('/top/featured', getFeaturedNews);
router.get('/category/:category', getNewsByCategory);
router.get('/detail/:slug', getNewsBySlug);

// Private routes
router.get('/my/articles', protect, getMyNews);
router.post('/', protect, newsRules, createNews);
router.put('/:id', protect, updateNews);
router.delete('/:id', protect, deleteNews);
router.post('/:id/like', protect, toggleLike);

module.exports = router;
