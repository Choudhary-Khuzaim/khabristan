const Category = require('../models/Category.model');

// @desc    Get all categories
// @route   GET /api/v1/categories
// @access  Public
const getCategories = async (req, res) => {
  try {
    const categories = await Category.find({ isActive: true })
      .sort('order')
      .populate('newsCount');
    res.json({ success: true, data: categories });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error fetching categories', error: error.message });
  }
};

// @desc    Create category (admin)
// @route   POST /api/v1/categories
// @access  Private/Admin
const createCategory = async (req, res) => {
  try {
    const { name, icon, description, order } = req.body;
    const slug = name.toLowerCase().replace(/\s+/g, '-');
    const category = await Category.create({ name, slug, icon, description, order });
    res.status(201).json({ success: true, data: category });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error creating category', error: error.message });
  }
};

module.exports = { getCategories, createCategory };
