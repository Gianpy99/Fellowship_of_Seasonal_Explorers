// Simple Node server to accept base64 PNG and save into assets/images/generated/
// Usage:
// 1. npm init -y
// 2. npm install express body-parser cors
// 3. node save_image_server.js

const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(cors());
app.use(bodyParser.json({limit: '50mb'}));

const PORT = 4567;
const OUTPUT_DIR = path.resolve(__dirname, '..', 'assets', 'images', 'generated');

if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  console.log('Created output dir:', OUTPUT_DIR);
}

app.post('/save-image', (req, res) => {
  try {
    const { filename, base64 } = req.body;
    if (!filename || !base64) {
      return res.status(400).json({ error: 'filename and base64 are required' });
    }

    // Strip data URL prefix if present
    const cleaned = base64.replace(/^data:image\/png;base64,/, '').replace(/^data:image\/jpeg;base64,/, '');
    const buffer = Buffer.from(cleaned, 'base64');
    const filePath = path.join(OUTPUT_DIR, filename);

    fs.writeFileSync(filePath, buffer);
    console.log('Saved image:', filePath);
    return res.json({ ok: true, path: filePath });
  } catch (err) {
    console.error('Error saving image:', err);
    return res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Image save server listening on http://localhost:${PORT}`);
  console.log(`Drop POST requests to http://localhost:${PORT}/save-image`);
});
