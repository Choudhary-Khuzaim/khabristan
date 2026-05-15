const router = require('express').Router();
const { getCategories, createCategory } = require('../controllers/category.controller');
const { protect, authorize } = require('../middleware/auth.middleware');

router.get('/', getCategories);
router.post('/', protect, authorize('admin'), createCategory);

module.exports = router;
