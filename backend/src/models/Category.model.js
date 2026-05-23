const mongoose = require('../config/mongoose.mock');

const categorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Category name is required'],
      unique: true,
      trim: true,
    },
    slug: {
      type: String,
      unique: true,
      lowercase: true,
    },
    icon: {
      type: String,
      default: 'public',
    },
    description: {
      type: String,
      default: '',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    order: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Virtual: news count per category
categorySchema.virtual('newsCount', {
  ref: 'News',
  localField: 'slug',
  foreignField: 'category',
  count: true,
});

module.exports = mongoose.model('Category', categorySchema);
