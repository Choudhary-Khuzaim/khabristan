const mongoose = require('mongoose');
const slugify = require('slugify');

const newsSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'News title is required'],
      trim: true,
      maxlength: [200, 'Title cannot exceed 200 characters'],
    },
    slug: {
      type: String,
      unique: true,
    },
    description: {
      type: String,
      required: [true, 'Description is required'],
      maxlength: [5000, 'Description cannot exceed 5000 characters'],
    },
    url: {
      type: String,
      default: '',
    },
    urlToImage: {
      type: String,
      default: 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=800',
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: ['general', 'business', 'entertainment', 'health', 'science', 'sports', 'technology'],
      default: 'general',
    },
    source: {
      type: String,
      default: 'KhabarIsTan User',
    },
    author: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    authorName: {
      type: String,
      default: 'Anonymous',
    },
    status: {
      type: String,
      enum: ['draft', 'pending', 'published', 'rejected'],
      default: 'published',
    },
    isFeatured: {
      type: Boolean,
      default: false,
    },
    views: {
      type: Number,
      default: 0,
    },
    likes: {
      type: Number,
      default: 0,
    },
    likedBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    tags: [String],
    publishedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  }
);

// Indexes for performance
newsSchema.index({ category: 1, publishedAt: -1 });
newsSchema.index({ author: 1, createdAt: -1 });
newsSchema.index({ title: 'text', description: 'text' });

// Generate slug before save
newsSchema.pre('save', function (next) {
  if (this.isModified('title')) {
    this.slug = slugify(this.title, {
      lower: true,
      strict: true,
    }) + '-' + Date.now().toString(36);
  }
  next();
});

module.exports = mongoose.model('News', newsSchema);
