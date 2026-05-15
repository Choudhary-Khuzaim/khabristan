const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
require('dotenv').config();

const connectDB = require('./config/db');

// Route imports
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const newsRoutes = require('./routes/news.routes');
const bookmarkRoutes = require('./routes/bookmark.routes');
const categoryRoutes = require('./routes/category.routes');
const externalNewsRoutes = require('./routes/externalNews.routes');

// Error handler middleware
const { errorHandler, notFound } = require('./middleware/error.middleware');

// Connect to MongoDB
connectDB();

const app = express();

// ============================================
// Global Middleware
// ============================================

// Security headers
app.use(helmet());

// CORS configuration
app.use(cors({
  origin: process.env.FRONTEND_URL || '*',
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
    message: '🏛️ KhabarIsTan API v1 — Premium News Backend',
    version: '2.1.0',
    endpoints: {
      auth: '/api/v1/auth',
      users: '/api/v1/users',
      news: '/api/v1/news',
      bookmarks: '/api/v1/bookmarks',
      categories: '/api/v1/categories',
      externalNews: '/api/v1/external-news',
    },
  });
});

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/news', newsRoutes);
app.use('/api/v1/bookmarks', bookmarkRoutes);
app.use('/api/v1/categories', categoryRoutes);
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

app.listen(PORT, () => {
  console.log(`\n🚀 KhabarIsTan Backend running in ${process.env.NODE_ENV} mode on port ${PORT}`);
  console.log(`📡 API Base: http://localhost:${PORT}/api/v1\n`);
});

module.exports = app;
