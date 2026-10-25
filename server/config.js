import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function int(value, fallback) {
  const n = Number.parseInt(value ?? '', 10);
  return Number.isFinite(n) && n >= 0 ? n : fallback;
}

export function loadConfig(env = process.env) {
  const appEnv = env.APP_ENV ?? 'development';
  const geminiKey = env.GEMINI_API_KEY || '';
  const openaiKey = env.OPENAI_API_KEY || '';
  // Explicit AI_PROVIDER wins; otherwise use whichever key is present (Gemini first).
  const requested = (env.AI_PROVIDER || '').toLowerCase();
  const provider = ['gemini', 'openai'].includes(requested)
    ? requested
    : geminiKey ? 'gemini' : openaiKey ? 'openai' : 'none';
  return {
    root,
    appEnv,
    production: appEnv === 'production',
    port: int(env.PORT, 8080),
    dataDir: path.resolve(env.DATA_DIR ?? path.join(root, '.data')),
    catalogFile: path.join(root, 'content', 'catalog.json'),
    seedImagesDir: path.join(root, 'content', 'seed-images'),
    webDir: path.join(root, 'dist'),
    devUser: appEnv === 'production' ? undefined : env.DEV_USER || 'dev',
    ai: {
      provider,
      gemini: {
        apiKey: geminiKey,
        imageModel: env.GEMINI_IMAGE_MODEL || 'gemini-nano-banana-2.1',
        textModel: env.GEMINI_TEXT_MODEL || 'gemini-3.1-flash-lite',
        contentModel: env.GEMINI_CONTENT_MODEL || 'gemini-3.8-flash',
      },
      openai: {
        apiKey: openaiKey,
        imageModel: env.OPENAI_IMAGE_MODEL || 'gpt-image-2.5-flare',
        imageQuality: env.OPENAI_IMAGE_QUALITY || 'medium',
        textModel: env.OPENAI_TEXT_MODEL || 'gpt-6-luna',
        contentModel: env.OPENAI_CONTENT_MODEL || 'gpt-6.1-sol',
      },
    },
    limits: {
      imagesPerDay: int(env.AI_IMAGES_PER_DAY, 40),
      textPerDay: int(env.AI_TEXT_PER_DAY, 300),
    },
  };
}
