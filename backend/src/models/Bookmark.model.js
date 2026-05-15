const mongoose = require('mongoose');

const bookmarkSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    // For internal news (citizen journalism)
    news: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'News',
      default: null,
    },
    // For external news (from NewsAPI) — store the article data directly
    externalArticle: {
      title: String,
      description: String,
      url: String,
      urlToImage: String,
      publishedAt: String,
      author: String,
      source: String,
    },
    // Type to distinguish internal vs external bookmarks
    type: {
      type: String,
      enum: ['internal', 'external'],
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// Ensure a user can't bookmark the same article twice
bookmarkSchema.index({ user: 1, news: 1 }, { unique: true, sparse: true });
bookmarkSchema.index(
  { user: 1, 'externalArticle.url': 1 },
  { unique: true, sparse: true }
);

module.exports = mongoose.model('Bookmark', bookmarkSchema);
