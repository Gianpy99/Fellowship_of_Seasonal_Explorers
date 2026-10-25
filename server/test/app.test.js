import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import sharp from 'sharp';
import { createApp } from '../app.js';
import { createStore } from '../store.js';
import { loadConfig } from '../config.js';
import { AiError } from '../ai.js';
import { buildCatalog } from '../../scripts/build-catalog.mjs';

const source = JSON.parse(readFileSync(new URL('../../content/source/seasonal_data.json', import.meta.url), 'utf8'));
const catalog = buildCatalog(source);
const PID = 'bergamotto_calabria';

const calls = { image: 0, json: 0, chat: 0 };
const fakeAi = {
  models: { imageModel: 'fake-image', textModel: 'fake-text' },
  async generateImage() {
    calls.image += 1;
    await new Promise((r) => setTimeout(r, 30));
    return sharp({ create: { width: 64, height: 64, channels: 3, background: '#88cc44' } }).png().toBuffer();
  },
  async generateJson() {
    calls.json += 1;
    return { questions: [{ question: 'When?', options: ['Winter', 'Summer', 'Never'], answer: 0, explanation: 'Yes!' }] };
  },
  async chat(system, messages) {
    calls.chat += 1;
    if (messages.at(-1).text === 'boom') throw new AiError('provider down');
    return `Ciao! (${messages.length})`;
  },
};

let server;
let base;
let dataDir;

async function call(method, url, { user = 'family', body, headers = {} } = {}) {
  const res = await fetch(base + url, {
    method,
    headers: { ...(user ? { 'Remote-User': user } : {}), ...(body ? { 'Content-Type': 'application/json' } : {}), ...headers },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = undefined;
  }
  return { status: res.status, json, headers: res.headers };
}

before(async () => {
  // A dot-folder like the local ".data" must still serve media files.
  dataDir = mkdtempSync(path.join(tmpdir(), '.seasonal-quest-'));
  const config = { ...loadConfig({ APP_ENV: 'production', DATA_DIR: dataDir, AI_IMAGES_PER_DAY: '3' }), webDir: path.join(dataDir, 'no-web') };
  const app = createApp({ config, catalog, store: createStore(dataDir), ai: fakeAi, logger: { info() {}, warn() {}, error() {} } });
  await new Promise((resolve) => {
    server = app.listen(0, '127.0.0.1', resolve);
  });
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => {
  server?.close();
  rmSync(dataDir, { recursive: true, force: true });
});

test('catalog maps every source category (no silent "fruit" fallback)', () => {
  const counts = Object.groupBy(catalog.products, (p) => p.category);
  assert.equal(catalog.products.length, 56);
  assert.equal(counts.animal.length, 8);
  assert.equal(counts.plant.length, 1);
  const p = catalog.products.find((x) => x.id === PID);
  assert.deepEqual(p.harvestMonths, [1, 2, 3, 11, 12]);
  assert.equal(p.stories.length, 7);
  assert.ok(p.coords.length === 2);
});

test('/health works without login', async () => {
  const res = await call('GET', '/health', { user: null });
  assert.equal(res.status, 200);
  assert.equal(res.json.status, 'ok');
  assert.ok(res.headers.get('content-security-policy'));
});

test('API requires Remote-User in production', async () => {
  assert.equal((await call('GET', '/api/me', { user: null })).status, 401);
  const me = await call('GET', '/api/me', { headers: { 'Remote-Groups': 'family, kids' } });
  assert.equal(me.status, 200);
  assert.deepEqual(me.json, { user: 'family', groups: ['family', 'kids'], ai: true });
});

test('explorers and progress are isolated per portal user', async () => {
  const created = await call('POST', '/api/explorers', { body: { name: '  Sofia <b> ', avatar: '🦊' } });
  assert.equal(created.status, 201);
  assert.equal(created.json.explorer.name, 'Sofia b');
  const eid = created.json.explorer.id;

  assert.equal((await call('POST', '/api/explorers', { body: { name: 'sofia b' } })).status, 409);
  assert.equal((await call('POST', '/api/explorers', { body: { name: '   ' } })).status, 400);

  const done = await call('PUT', `/api/explorers/${eid}/completed/${PID}`);
  assert.equal(done.status, 200);
  assert.ok(done.json.explorer.completed[PID]);
  assert.equal((await call('PUT', `/api/explorers/${eid}/completed/not_a_product`)).status, 404);

  const quiz = await call('POST', `/api/explorers/${eid}/quiz/${PID}`, { body: { score: 3, total: 4 } });
  assert.deepEqual(quiz.json.explorer.quizzes[PID].best, 3);
  assert.equal((await call('POST', `/api/explorers/${eid}/quiz/${PID}`, { body: { score: 9, total: 4 } })).status, 400);

  const other = await call('GET', '/api/explorers', { user: 'someone-else' });
  assert.deepEqual(other.json.explorers, []);
  assert.equal((await call('PUT', `/api/explorers/${eid}/completed/${PID}`, { user: 'someone-else' })).status, 404);

  const undone = await call('DELETE', `/api/explorers/${eid}/completed/${PID}`);
  assert.deepEqual(undone.json.explorer.completed, {});
});

test('images are generated once, deduplicated, cached and served as webp', async () => {
  const [a, b] = await Promise.all([
    call('POST', `/api/products/${PID}/images/adv-1`),
    call('POST', `/api/products/${PID}/images/adv-1`),
  ]);
  assert.equal(a.status, 200);
  assert.equal(a.json.version, b.json.version);
  assert.equal(calls.image, 1);

  const again = await call('POST', `/api/products/${PID}/images/adv-1`);
  assert.equal(again.json.cached, true);
  assert.equal(calls.image, 1);

  const media = await fetch(`${base}/media/${PID}/adv-1.webp?v=${a.json.version}`);
  assert.equal(media.status, 200);
  assert.equal(media.headers.get('content-type'), 'image/webp');
  assert.match(media.headers.get('cache-control'), /immutable/);

  const catalogRes = await call('GET', '/api/catalog');
  assert.equal(catalogRes.json.images[PID]['adv-1'], a.json.version);

  assert.equal((await call('POST', `/api/products/${PID}/images/..%2F..%2Fetc`)).status, 404);
  assert.equal((await fetch(`${base}/media/${PID}/..%2Fx.webp`)).status, 404);
});

test('image generation respects the daily quota', async () => {
  await call('POST', `/api/products/${PID}/images/icon`, { user: 'quota' });
  await call('POST', `/api/products/${PID}/images/cal-1`, { user: 'quota' });
  await call('POST', `/api/products/${PID}/images/cal-2`, { user: 'quota' });
  const res = await call('POST', `/api/products/${PID}/images/eng-1`, { user: 'quota' });
  assert.equal(res.status, 429);
  assert.equal(res.json.error, 'daily_limit');
});

test('quiz is generated once per product and language', async () => {
  const first = await call('GET', `/api/products/${PID}/quiz?lang=en`);
  const second = await call('GET', `/api/products/${PID}/quiz?lang=en`);
  assert.equal(first.status, 200);
  assert.equal(first.json.questions.length, 1);
  assert.deepEqual(second.json, first.json);
  assert.equal(calls.json, 1);
});

test('chat validates input and reports AI failures as 502', async () => {
  assert.equal((await call('POST', `/api/products/${PID}/chat`, { body: { messages: [] } })).status, 400);
  const long = 'x'.repeat(5000);
  const ok = await call('POST', `/api/products/${PID}/chat`, {
    body: { lang: 'it', messages: [{ role: 'user', text: 'Ciao' }, { role: 'nonna', text: 'Ciao!' }, { role: 'user', text: long }] },
  });
  assert.equal(ok.status, 200);
  assert.equal(ok.json.reply, 'Ciao! (3)');
  const failed = await call('POST', `/api/products/${PID}/chat`, { body: { messages: [{ role: 'user', text: 'boom' }] } });
  assert.equal(failed.status, 502);
  assert.equal(failed.json.error, 'ai_failed');
});

test('AI endpoints return 503 when no key is configured', async () => {
  const dir = mkdtempSync(path.join(tmpdir(), 'seasonal-quest-noai-'));
  const config = { ...loadConfig({ APP_ENV: 'development', DATA_DIR: dir }), webDir: path.join(dir, 'none') };
  const app = createApp({ config, catalog, store: createStore(dir), ai: null, logger: { info() {}, warn() {}, error() {} } });
  const srv = await new Promise((resolve) => {
    const s = app.listen(0, '127.0.0.1', () => resolve(s));
  });
  try {
    const url = `http://127.0.0.1:${srv.address().port}`;
    const res = await fetch(`${url}/api/products/${PID}/images/icon`, { method: 'POST' });
    assert.equal(res.status, 503);
    const me = await (await fetch(`${url}/api/me`)).json();
    assert.equal(me.user, 'dev');
    assert.equal(me.ai, false);
  } finally {
    srv.close();
    rmSync(dir, { recursive: true, force: true });
  }
});
