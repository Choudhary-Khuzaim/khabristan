const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });



// Route imports
// const authRoutes = require('./routes/auth.routes');
// const userRoutes = require('./routes/user.routes');
// const newsRoutes = require('./routes/news.routes');
// const bookmarkRoutes = require('./routes/bookmark.routes');
// const categoryRoutes = require('./routes/category.routes');
const externalNewsRoutes = require('./routes/externalNews.routes');

// Error handler middleware
const { errorHandler, notFound } = require('./middleware/error.middleware');

const app = express();

// ============================================
// Global Middleware
// ============================================

// Security headers
app.use(helmet());

// CORS configuration — allow Flutter apps from any origin
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Body parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Logging (development only)
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Static files (uploads)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ============================================
// API Routes
// ============================================

app.get('/api/v1', (req, res) => {
  res.json({
    success: true,
    message: '🏛️ KhabarIsTan API v2.1 — Premium News Backend',
    version: '2.1.0',
    endpoints: {
      auth: '/api/v1/auth',
      users: '/api/v1/users',
      news: '/api/v1/news',
      bookmarks: '/api/v1/bookmarks',
      categories: '/api/v1/categories',
      externalNews: '/api/v1/external-news',
    },
    dailyNewsEndpoints: {
      daily: '/api/v1/external-news/daily?category=general&page=1&limit=20',
      featured: '/api/v1/external-news/featured?limit=5',
      search: '/api/v1/external-news/search?q=your_query',
      stats: '/api/v1/external-news/stats',
    },
  });
});

// app.use('/api/v1/auth', authRoutes);
// app.use('/api/v1/users', userRoutes);
// app.use('/api/v1/news', newsRoutes);
// app.use('/api/v1/bookmarks', bookmarkRoutes);
// app.use('/api/v1/categories', categoryRoutes);
app.use('/api/v1/external-news', externalNewsRoutes);

// ============================================
// Error Handling
// ============================================
app.use(notFound);
app.use(errorHandler);

// ============================================
// Start Server
// ============================================
const PORT = process.env.PORT || 5000;

const startServer = async () => {
  try {

    app.listen(PORT, () => {
      console.log(`\n🚀 ═══════════════════════════════════════════`);
      console.log(`   KhabarIsTan Backend v2.1.0`);
      console.log(`   Mode: ${process.env.NODE_ENV || 'development'}`);
      console.log(`   Port: ${PORT}`);
      console.log(`   API:  http://localhost:${PORT}/api/v1`);
      console.log(`   ═══════════════════════════════════════════\n`);

    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();

module.exports = app;
