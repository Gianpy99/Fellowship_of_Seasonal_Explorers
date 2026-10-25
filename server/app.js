import express from 'express';
import compression from 'compression';
import sharp from 'sharp';
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { cleanExplorerName, createQuota } from './store.js';
import { AiError } from './ai.js';
import { iconPrompt, storyPrompt, quizPrompt, nonnaSystemPrompt, QUIZ_SCHEMA } from './prompts.js';

const LANGS = new Set(['it', 'en']);
const MAX_CHAT_TURNS = 12;
const MAX_CHAT_CHARS = 400;

const CSP = [
  "default-src 'self'",
  "img-src 'self' data: blob: https://*.tile.openstreetmap.org",
  "style-src 'self' 'unsafe-inline'",
  "script-src 'self'",
  "connect-src 'self'",
  "font-src 'self'",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
].join('; ');

class HttpError extends Error {
  constructor(status, code, message = code) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

function validQuiz(quiz) {
  return (
    Array.isArray(quiz?.questions) &&
    quiz.questions.length > 0 &&
    quiz.questions.every(
      (q) =>
        typeof q.question === 'string' &&
        Array.isArray(q.options) &&
        q.options.length >= 2 &&
        q.options.every((o) => typeof o === 'string') &&
        Number.isInteger(q.answer) &&
        q.answer >= 0 &&
        q.answer < q.options.length,
    )
  );
}

/**
 * @param {{config: ReturnType<import('./config.js').loadConfig>, catalog: {products: any[]}, store: ReturnType<import('./store.js').createStore>, ai: any, logger?: Pick<Console,'info'|'warn'|'error'>}} deps
 */
export function createApp({ config, catalog, store, ai, logger = console }) {
  const app = express();
  const products = new Map(catalog.products.map((p) => [p.id, p]));
  const imageIndex = store.scanImages();
  const quota = createQuota(config.limits);
  const inflight = new Map();

  app.disable('x-powered-by');
  app.set('trust proxy', true);
  app.use(compression());
  app.use((req, res, next) => {
    res.set({
      'Content-Security-Policy': CSP,
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Permissions-Policy': 'camera=(), microphone=(), geolocation=()',
    });
    next();
  });

  app.get('/health', (req, res) => res.json({ status: 'ok', products: products.size }));

  // ---- Identity (portal contract: Remote-User from Caddy; DEV_USER only outside production)
  const api = express.Router();
  api.use(express.json({ limit: '32kb' }));
  api.use((req, res, next) => {
    const user = req.get('Remote-User') || config.devUser;
    if (!user) return res.status(401).json({ error: 'not_authenticated' });
    req.user = user;
    req.groups = (req.get('Remote-Groups') ?? '').split(',').map((g) => g.trim()).filter(Boolean);
    next();
  });

  const product = (req) => {
    const p = products.get(req.params.pid);
    if (!p) throw new HttpError(404, 'unknown_product');
    return p;
  };
  const lang = (value) => (LANGS.has(value) ? value : 'it');
  const requireAi = (req, kind) => {
    if (!ai) throw new HttpError(503, 'ai_disabled', 'AI features are not configured on this server');
    if (!quota.take(req.user, kind)) throw new HttpError(429, 'daily_limit', 'Daily AI limit reached, try again tomorrow');
  };

  api.get('/me', (req, res) => {
    res.json({ user: req.user, groups: req.groups, ai: Boolean(ai) });
  });

  api.get('/catalog', (req, res) => {
    res.set('Cache-Control', 'no-cache');
    res.json({ products: catalog.products, images: imageIndex });
  });

  // ---- Explorers (kid profiles inside one portal account) and their progress
  api.get('/explorers', async (req, res) => res.json({ explorers: await store.listExplorers(req.user) }));

  api.post('/explorers', async (req, res) => {
    const name = cleanExplorerName(req.body?.name);
    if (!name) throw new HttpError(400, 'invalid_name');
    const result = await store.addExplorer(req.user, name, req.body?.avatar);
    if (result.error) throw new HttpError(409, result.error);
    res.status(201).json({ explorer: result.explorer });
  });

  api.delete('/explorers/:eid', async (req, res) => {
    if (!(await store.removeExplorer(req.user, req.params.eid))) throw new HttpError(404, 'unknown_explorer');
    res.status(204).end();
  });

  const setCompleted = (done) => async (req, res) => {
    product(req);
    const explorer = await store.setCompleted(req.user, req.params.eid, req.params.pid, done);
    if (!explorer) throw new HttpError(404, 'unknown_explorer');
    res.json({ explorer });
  };
  api.put('/explorers/:eid/completed/:pid', setCompleted(true));
  api.delete('/explorers/:eid/completed/:pid', setCompleted(false));

  api.post('/explorers/:eid/quiz/:pid', async (req, res) => {
    product(req);
    const { score, total } = req.body ?? {};
    if (!Number.isInteger(total) || total < 1 || total > 20 || !Number.isInteger(score) || score < 0 || score > total) {
      throw new HttpError(400, 'invalid_score');
    }
    const explorer = await store.recordQuiz(req.user, req.params.eid, req.params.pid, score, total);
    if (!explorer) throw new HttpError(404, 'unknown_explorer');
    res.json({ explorer });
  });

  // ---- AI: illustrations (generated once, cached on disk, shared by everyone)
  async function generateImage(p, slot) {
    const story = slot === 'icon' ? null : p.stories.find((s) => s.id === slot);
    const prompt = story ? storyPrompt(p, story) : iconPrompt(p);
    const started = Date.now();
    const raw = await ai.generateImage(prompt, { aspectRatio: story ? '4:3' : '1:1' });
    const webp = await sharp(raw)
      .resize(story ? { width: 1200, withoutEnlargement: true } : { width: 512, height: 512, fit: 'cover' })
      .webp({ quality: 82 })
      .toBuffer();
    await store.saveImage(p.id, slot, webp);
    const version = Date.now();
    (imageIndex[p.id] ??= {})[slot] = version;
    logger.info(`image ${p.id}/${slot}: ${(webp.length / 1024).toFixed(0)} KB in ${Date.now() - started} ms`);
    return version;
  }

  api.post('/products/:pid/images/:slot', async (req, res) => {
    const p = product(req);
    const { slot } = req.params;
    if (slot !== 'icon' && !p.stories.some((s) => s.id === slot)) throw new HttpError(404, 'unknown_slot');
    const existing = imageIndex[p.id]?.[slot];
    if (existing && !req.body?.redo) return res.json({ slot, version: existing, cached: true });

    const key = `${p.id}/${slot}`;
    if (!inflight.has(key)) {
      requireAi(req, 'imagesPerDay');
      inflight.set(key, generateImage(p, slot).finally(() => inflight.delete(key)));
    }
    res.json({ slot, version: await inflight.get(key), cached: false });
  });

  app.get('/media/:pid/:file', (req, res, next) => {
    const match = /^([a-z0-9-]+)\.webp$/.exec(req.params.file);
    if (!products.has(req.params.pid) || !match || !imageIndex[req.params.pid]?.[match[1]]) return next();
    res.type('image/webp').sendFile(`${req.params.pid}/${match[1]}.webp`, { root: store.imagesDir, maxAge: '1y', immutable: true });
  });

  // ---- AI: quiz (generated once per product+language, then cached)
  api.get('/products/:pid/quiz', async (req, res) => {
    const p = product(req);
    const l = lang(req.query.lang);
    const cached = await store.getQuiz(p.id, l);
    if (cached) return res.json(cached);

    const key = `quiz:${p.id}:${l}`;
    if (!inflight.has(key)) {
      requireAi(req, 'textPerDay');
      const job = (async () => {
        const quiz = await ai.generateJson(quizPrompt(p, l), QUIZ_SCHEMA);
        if (!validQuiz(quiz)) throw new HttpError(502, 'bad_quiz', 'The quiz came back malformed, please retry');
        const result = { lang: l, questions: quiz.questions.slice(0, 6) };
        await store.saveQuiz(p.id, l, result);
        return result;
      })().finally(() => inflight.delete(key));
      inflight.set(key, job);
    }
    res.json(await inflight.get(key));
  });

  // ---- AI: chat with Nonna Rosa (kid-safe, on-topic, short)
  api.post('/products/:pid/chat', async (req, res) => {
    const p = product(req);
    const l = lang(req.body?.lang);
    const raw = Array.isArray(req.body?.messages) ? req.body.messages : [];
    const messages = raw
      .slice(-MAX_CHAT_TURNS)
      .filter((m) => m && typeof m.text === 'string' && m.text.trim())
      .map((m) => ({ role: m.role === 'user' ? 'user' : 'model', text: m.text.trim().slice(0, MAX_CHAT_CHARS) }));
    if (!messages.length || messages.at(-1).role !== 'user') throw new HttpError(400, 'invalid_messages');
    requireAi(req, 'textPerDay');
    const reply = await ai.chat(nonnaSystemPrompt(p, l), messages);
    res.json({
      reply: reply || (l === 'it' ? 'Mmm, non so cosa dire, tesoro! Chiedimi qualcos\'altro su questo cibo. 🍋' : "Hmm, I'm not sure, sweetheart! Ask me something else about this food. 🍋"),
    });
  });

  app.use('/api', api);
  app.use('/api', (req, res) => res.status(404).json({ error: 'not_found' }));

  // ---- Front-end (Vite build). Hashed assets are immutable; index.html is always revalidated.
  if (existsSync(config.webDir)) {
    app.use('/assets', express.static(path.join(config.webDir, 'assets'), { immutable: true, maxAge: '1y', index: false }));
    app.use(express.static(config.webDir, { index: false, maxAge: '1h' }));
    const indexHtml = readFileSync(path.join(config.webDir, 'index.html'));
    app.get('/{*splat}', (req, res) => res.set('Cache-Control', 'no-cache').type('html').send(indexHtml));
  }

  app.use((err, req, res, next) => {
    if (res.headersSent) return next(err);
    res.set('Cache-Control', 'no-store');
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.code, message: err.message });
    if (err.type === 'entity.parse.failed' || err.type === 'entity.too.large') return res.status(400).json({ error: 'bad_request' });
    if (err.status >= 400 && err.status < 500) return res.status(err.status).json({ error: err.status === 404 ? 'not_found' : 'bad_request' });
    logger.error(`${req.method} ${req.path} failed:`, err.message);
    if (err instanceof AiError) return res.status(502).json({ error: 'ai_failed', message: 'The AI could not answer right now, please try again.' });
    res.status(500).json({ error: 'server_error', message: 'Something went wrong.' });
  });

  return app;
}
