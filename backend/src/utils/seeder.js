const mongoose = require('../config/mongoose.mock');
require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });

const User = require('../models/User.model');
const News = require('../models/News.model');
const Category = require('../models/Category.model');

const categories = [
  { name: 'General', slug: 'general', icon: 'public', order: 0 },
  { name: 'Business', slug: 'business', icon: 'business', order: 1 },
  { name: 'Entertainment', slug: 'entertainment', icon: 'movie', order: 2 },
  { name: 'Health', slug: 'health', icon: 'health_and_safety', order: 3 },
  { name: 'Science', slug: 'science', icon: 'science', order: 4 },
  { name: 'Sports', slug: 'sports', icon: 'sports_soccer', order: 5 },
  { name: 'Technology', slug: 'technology', icon: 'computer', order: 6 },
];

const seedDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB for seeding');

    // Seed categories
    await Category.deleteMany({});
    await Category.insertMany(categories);
    console.log('📁 Categories seeded');

    // Create demo admin user
    const existingAdmin = await User.findOne({ username: 'admin' });
    if (!existingAdmin) {
      await User.create({
        name: 'Admin',
        email: 'admin@khabaristan.com',
        username: 'admin',
        password: 'admin123',
        role: 'admin',
        isVerified: true,
      });
      console.log('👤 Admin user created (admin / admin123)');
    }

    // Create demo journalist
    const existingJournalist = await User.findOne({ username: 'khuzaim' });
    if (!existingJournalist) {
      const journalist = await User.create({
        name: 'Khuzaim Sajjad',
        email: 'khuzaim@khabaristan.com',
        username: 'khuzaim',
        password: 'khuzaim123',
        role: 'journalist',
        isVerified: true,
        bio: 'Founder & Lead Journalist at KhabarIsTan',
        location: 'Pakistan',
      });

      // Create sample news articles
      const sampleNews = [
        { title: 'KhabarIsTan Launches Premium News Platform', description: 'KhabarIsTan, a revolutionary news platform, has officially launched with premium features including AI-powered voice reporting, citizen journalism tools, and a luxury Royal Blue & Gold interface.', category: 'technology', isFeatured: true },
        { title: 'Pakistan Celebrates Cultural Heritage Week', description: 'Festivities and cultural events are taking place across Pakistan to mark the annual Cultural Heritage Week, showcasing art, music, and traditional crafts.', category: 'general', isFeatured: true },
        { title: 'Major Development Projects Approved', description: 'The local government has approved several infrastructure projects aimed at improving public transport and green spaces in city centers.', category: 'general' },
        { title: 'Global Markets Show Strong Recovery', description: 'Stock markets worldwide are showing positive trends as investors respond to encouraging economic data and corporate earnings reports.', category: 'business', isFeatured: true },
        { title: 'New Breakthrough in Renewable Energy', description: 'Scientists have achieved a major breakthrough in solar cell efficiency, potentially revolutionizing the renewable energy sector.', category: 'science' },
        { title: 'Premier League Season Kicks Off', description: 'The new Premier League season starts this weekend with exciting matchups and new signings promising an action-packed campaign.', category: 'sports' },
        { title: 'WHO Announces New Health Guidelines', description: 'The World Health Organization has released updated guidelines focusing on mental health awareness and preventive healthcare.', category: 'health' },
      ];

      for (const article of sampleNews) {
        await News.create({ ...article, author: journalist._id, authorName: journalist.name, source: 'KhabarIsTan' });
      }
      console.log('📰 Sample news articles created');
    }

    console.log('\n✅ Database seeded successfully!\n');
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error.message);
    process.exit(1);
  }
};

seedDB();
