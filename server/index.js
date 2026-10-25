import { readFileSync } from 'node:fs';
import { loadConfig } from './config.js';
import { createStore } from './store.js';
import { createGeminiAi } from './ai.js';
import { createApp } from './app.js';

const config = loadConfig();
const catalog = JSON.parse(readFileSync(config.catalogFile, 'utf8'));
const store = createStore(config.dataDir);
const seeded = store.seedImages(config.seedImagesDir);
const ai = createGeminiAi(config.gemini);

if (config.production && !process.env.GEMINI_API_KEY) console.warn('GEMINI_API_KEY is not set: AI features are disabled.');

const app = createApp({ config, catalog, store, ai });
const server = app.listen(config.port, '0.0.0.0', () => {
  console.info(
    `Seasonal Quest on :${config.port} (${config.appEnv}) | ${catalog.products.length} products | data ${config.dataDir}` +
      (seeded ? ` | seeded ${seeded} images` : '') +
      ` | AI ${ai ? `${ai.models.imageModel} + ${ai.models.textModel}` : 'disabled'}` +
      (config.devUser ? ` | DEV_USER=${config.devUser}` : ''),
  );
});

for (const signal of ['SIGTERM', 'SIGINT']) {
  process.on(signal, () => server.close(() => process.exit(0)));
}
