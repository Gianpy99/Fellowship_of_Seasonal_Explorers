import { readFileSync } from 'node:fs';
import { loadConfig } from './config.js';
import { createStore } from './store.js';
import { createAi } from './ai.js';
import { createApp } from './app.js';

const config = loadConfig();
const catalog = JSON.parse(readFileSync(config.catalogFile, 'utf8'));
const store = createStore(config.dataDir);
const seeded = store.seedImages(config.seedImagesDir);
const ai = createAi(config.ai);

if (config.production && !ai) {
  console.warn(`AI features are disabled: no API key for provider "${config.ai.provider}" (set GEMINI_API_KEY or OPENAI_API_KEY).`);
}

const app = createApp({ config, catalog, store, ai });
const server = app.listen(config.port, '0.0.0.0', () => {
  console.info(
    `Seasonal Quest on :${config.port} (${config.appEnv}) | ${catalog.products.length} products | data ${config.dataDir}` +
      (seeded ? ` | seeded ${seeded} images` : '') +
      ` | AI ${ai ? `${ai.provider}: ${ai.models.imageModel} + ${ai.models.textModel}` : 'disabled'}` +
      (config.devUser ? ` | DEV_USER=${config.devUser}` : ''),
  );
});

for (const signal of ['SIGTERM', 'SIGINT']) {
  process.on(signal, () => server.close(() => process.exit(0)));
}
