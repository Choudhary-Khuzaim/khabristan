const router = require('express').Router();
const {
  getTopHeadlines,
  getEverything,
  getDailyNews,
  getFeaturedDailyNews,
  searchDailyNews,
  triggerFetchNow,
  triggerCleanup,
  getNewsStats,
} = require('../controllers/externalNews.controller');
const { protect, authorize } = require('../middleware/auth.middleware');
const { apiLimiter } = require('../middleware/rateLimiter.middleware');

// ============================================
// Public routes (used by Flutter app)
// ============================================

// PRIMARY: Cached daily news from local DB (fast, no API key exposed)
router.get('/daily', getDailyNews);
router.get('/featured', getFeaturedDailyNews);
router.get('/search', searchDailyNews);
router.get('/stats', getNewsStats);

// Live proxy routes (fallback — hits NewsAPI directly through backend)
router.get('/top-headlines', apiLimiter, getTopHeadlines);
router.get('/everything', apiLimiter, getEverything);

// ============================================
// Admin routes (manual triggers)
// ============================================
router.post('/fetch-now', protect, authorize('admin'), triggerFetchNow);
router.post('/cleanup', protect, authorize('admin'), triggerCleanup);

module.exports = router;
