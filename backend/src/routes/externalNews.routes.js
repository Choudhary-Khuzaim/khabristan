const router = require('express').Router();
const { getTopHeadlines, getEverything } = require('../controllers/externalNews.controller');
const { apiLimiter } = require('../middleware/rateLimiter.middleware');

router.get('/top-headlines', apiLimiter, getTopHeadlines);
router.get('/everything', apiLimiter, getEverything);

module.exports = router;
