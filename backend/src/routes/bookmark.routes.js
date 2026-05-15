const router = require('express').Router();
const { getBookmarks, addBookmark, removeBookmark, checkBookmark } = require('../controllers/bookmark.controller');
const { protect } = require('../middleware/auth.middleware');

router.use(protect); // All bookmark routes require auth

router.get('/', getBookmarks);
router.post('/', addBookmark);
router.post('/check', checkBookmark);
router.delete('/:id', removeBookmark);

module.exports = router;
