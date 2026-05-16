const { fetchAllDailyNews, cleanupOldNews } = require('./newsFetcher.service');

// ============================================
// Simple Cron-like Scheduler (no dependencies)
// ============================================

class SimpleScheduler {
  constructor() {
    this._intervals = [];
    this._timeouts = [];
  }

  // Schedule a job to run at a specific interval
  scheduleInterval(name, intervalMs, job) {
    console.log(`⏰ Scheduled: "${name}" every ${Math.round(intervalMs / 60000)} minutes`);
    const id = setInterval(async () => {
      console.log(`\n⏰ Running scheduled job: "${name}" at ${new Date().toISOString()}`);
      try {
        await job();
      } catch (error) {
        console.error(`❌ Scheduled job "${name}" failed:`, error.message);
      }
    }, intervalMs);
    this._intervals.push({ name, id });
    return id;
  }

  // Schedule a one-time delayed job
  scheduleOnce(name, delayMs, job) {
    console.log(`⏰ Scheduled once: "${name}" in ${Math.round(delayMs / 1000)} seconds`);
    const id = setTimeout(async () => {
      console.log(`\n⏰ Running one-time job: "${name}" at ${new Date().toISOString()}`);
      try {
        await job();
      } catch (error) {
        console.error(`❌ One-time job "${name}" failed:`, error.message);
      }
    }, delayMs);
    this._timeouts.push({ name, id });
    return id;
  }

  // Stop all scheduled jobs
  stopAll() {
    this._intervals.forEach(({ name, id }) => {
      clearInterval(id);
      console.log(`🛑 Stopped interval: "${name}"`);
    });
    this._timeouts.forEach(({ name, id }) => {
      clearTimeout(id);
      console.log(`🛑 Stopped timeout: "${name}"`);
    });
    this._intervals = [];
    this._timeouts = [];
  }
}

// ============================================
// Initialize all scheduled jobs
// ============================================
function initScheduler() {
  const scheduler = new SimpleScheduler();

  console.log('\n📅 ═══════════════════════════════════════');
  console.log('   KhabarIsTan — News Scheduler Active');
  console.log('   ═══════════════════════════════════════\n');

  // 1) Fetch news on startup (delay 10 seconds to let DB connect)
  scheduler.scheduleOnce('Initial News Fetch', 10 * 1000, async () => {
    await fetchAllDailyNews();
  });

  // 2) Fetch fresh news every 3 hours
  const THREE_HOURS = 3 * 60 * 60 * 1000;
  scheduler.scheduleInterval('News Fetch (3-hourly)', THREE_HOURS, async () => {
    await fetchAllDailyNews();
  });

  // 3) Cleanup old news every 24 hours
  const TWENTY_FOUR_HOURS = 24 * 60 * 60 * 1000;
  scheduler.scheduleInterval('Old News Cleanup (daily)', TWENTY_FOUR_HOURS, async () => {
    await cleanupOldNews();
  });

  return scheduler;
}

module.exports = { initScheduler, SimpleScheduler };
