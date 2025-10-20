const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = 3000;

// Cartella per salvare le immagini
const IMAGES_DIR = path.join(__dirname, 'server_images');
if (!fs.existsSync(IMAGES_DIR)) {
  fs.mkdirSync(IMAGES_DIR, { recursive: true });
  console.log(`📁 Created images directory: ${IMAGES_DIR}`);
}

// Store images in memory (cache)
const imageStore = {};

// Load existing images from disk on startup
function loadImagesFromDisk() {
  try {
    const files = fs.readdirSync(IMAGES_DIR);
    files.forEach(file => {
      const filePath = path.join(IMAGES_DIR, file);
      const key = file.replace('.b64', '');
      const data = fs.readFileSync(filePath, 'utf8');
      imageStore[key] = data;
    });
    console.log(`📂 Loaded ${files.length} images from disk`);
  } catch (err) {
    console.error('Error loading images:', err);
  }
}

// File path for progress persistence
const PROGRESS_FILE = path.join(IMAGES_DIR, 'progress.json');

// Load progress from disk on startup
function loadProgressFromDisk() {
  try {
    if (fs.existsSync(PROGRESS_FILE)) {
      const data = fs.readFileSync(PROGRESS_FILE, 'utf8');
      userProgress = JSON.parse(data);
      console.log(`📋 Loaded progress from disk: ${userProgress.completedQuestIds.length} quests`);
    } else {
      console.log(`📋 No progress file found, starting fresh`);
    }
  } catch (err) {
    console.error('Error loading progress:', err);
  }
}

// Save progress to disk
function saveProgressToDisk() {
  try {
    fs.writeFileSync(PROGRESS_FILE, JSON.stringify(userProgress, null, 2));
    console.log(`💾 Progress saved to disk: ${userProgress.completedQuestIds.length} quests`);
  } catch (err) {
    console.error('Error saving progress to disk:', err);
  }
}

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' })); // Allow large base64 images

// GET: Retrieve image
app.get('/api/images/:key', (req, res) => {
  const { key } = req.params;
  
  if (imageStore[key]) {
    console.log(`✅ Retrieved: ${key}`);
    res.json({ data: imageStore[key] });
  } else {
    console.log(`❌ Not found: ${key}`);
    res.status(404).json({ error: 'Image not found' });
  }
});

// POST: Save image
app.post('/api/images/:key', (req, res) => {
  const { key } = req.params;
  const { data } = req.body;
  
  if (!data) {
    return res.status(400).json({ error: 'Missing image data' });
  }
  
  // Save to memory cache
  imageStore[key] = data;
  
  // Save to disk for persistence
  const filePath = path.join(IMAGES_DIR, `${key}.b64`);
  fs.writeFileSync(filePath, data);
  
  console.log(`💾 Saved: ${key} (${(data.length / 1024).toFixed(2)} KB)`);
  res.json({ success: true, key });
});

// DELETE: Delete image
app.delete('/api/images/:key', (req, res) => {
  const { key } = req.params;
  
  // Delete from memory
  delete imageStore[key];
  
  // Delete from disk
  const filePath = path.join(IMAGES_DIR, `${key}.b64`);
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }
  
  console.log(`🗑️ Deleted: ${key}`);
  res.json({ success: true });
});

// GET: List all keys
app.get('/api/images', (req, res) => {
  const keys = Object.keys(imageStore);
  const totalSize = Object.values(imageStore).reduce((sum, data) => sum + data.length, 0);
  console.log(`📊 Listed: ${keys.length} images (${(totalSize / 1024 / 1024).toFixed(2)} MB)`);
  res.json({ 
    images: keys.length, 
    size_mb: (totalSize / 1024 / 1024).toFixed(2),
    keys 
  });
});

// DELETE: Clear all
app.delete('/api/images', (req, res) => {
  const count = Object.keys(imageStore).length;
  Object.keys(imageStore).forEach(key => delete imageStore[key]);
  
  // Clear disk
  try {
    const files = fs.readdirSync(IMAGES_DIR);
    files.forEach(file => {
      fs.unlinkSync(path.join(IMAGES_DIR, file));
    });
  } catch (err) {
    console.error('Error clearing disk cache:', err);
  }
  
  console.log(`🗑️ Cleared: ${count} images`);
  res.json({ success: true, cleared: count });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', images: Object.keys(imageStore).length });
});

// ============================================
// USER PROGRESS ENDPOINTS
// ============================================

// Store progress in memory
let userProgress = {
  completedQuestIds: [],
  visitedLocationIds: [],
  unlockedBadges: [],
  lastUpdated: new Date().toISOString(),
};

// GET: Retrieve user progress
app.get('/api/progress', (req, res) => {
  console.log(`📊 Retrieved progress: ${userProgress.completedQuestIds.length} quests completed`);
  // Convert to snake_case for Dart client compatibility
  res.json({
    completed_quest_ids: userProgress.completedQuestIds,
    visited_location_ids: userProgress.visitedLocationIds,
    unlocked_badges: userProgress.unlockedBadges,
    last_updated: userProgress.lastUpdated,
  });
});

// POST: Save user progress
app.post('/api/progress', (req, res) => {
  try {
    console.log(`📥 POST /api/progress - Body:`, req.body);
    
    // Handle both snake_case (from Dart) and camelCase
    const completedQuestIds = req.body.completed_quest_ids || req.body.completedQuestIds || [];
    const visitedLocationIds = req.body.visited_location_ids || req.body.visitedLocationIds || [];
    const unlockedBadges = req.body.unlocked_badges || req.body.unlockedBadges || [];
    const lastUpdated = req.body.last_updated || req.body.lastUpdated || new Date().toISOString();
    
    if (!Array.isArray(completedQuestIds)) {
      console.log(`❌ Invalid completedQuestIds:`, completedQuestIds);
      return res.status(400).json({ error: 'Missing or invalid completed_quest_ids' });
    }
    
    userProgress = {
      completedQuestIds,
      visitedLocationIds: visitedLocationIds || [],
      unlockedBadges: unlockedBadges || [],
      lastUpdated: lastUpdated || new Date().toISOString(),
    };
    
    // Save to disk for persistence
    saveProgressToDisk();
    
    console.log(`💾 Saved progress: ${completedQuestIds.length} quests completed`);
    res.json({ success: true, progress: userProgress });
  } catch (err) {
    console.error('Error saving progress:', err);
    res.status(500).json({ error: err.message });
  }
});

// DELETE: Clear progress
app.delete('/api/progress', (req, res) => {
  userProgress = {
    completedQuestIds: [],
    visitedLocationIds: [],
    unlockedBadges: [],
    lastUpdated: new Date().toISOString(),
  };
  
  // Delete from disk
  if (fs.existsSync(PROGRESS_FILE)) {
    fs.unlinkSync(PROGRESS_FILE);
  }
  
  console.log(`🗑️ Cleared all progress`);
  res.json({ success: true, progress: userProgress });
});

app.listen(PORT, () => {
  console.log(`🚀 Image server running on http://localhost:${PORT}`);
  console.log(`🛡️ Store: Memory cache + Persistent disk storage`);
  console.log(`📁 Image directory: ${IMAGES_DIR}`);
  console.log(`📊 User Progress endpoints available`);
  loadImagesFromDisk();
  loadProgressFromDisk();
});
