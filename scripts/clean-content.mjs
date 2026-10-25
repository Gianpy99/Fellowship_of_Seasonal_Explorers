// One-off AI pass that fixes the bilingual content (wrong-language text, grammar, gender
// agreement) and adds a per-product emoji and fun fact. Results go to
// content/content-overrides.json, which build-catalog.mjs merges; the raw source is untouched.
//
// Usage:
//   GEMINI_API_KEY=... node scripts/clean-content.mjs [--model=gemini-3.8-flash] [--only=id1,id2] [--force] [--dry-run]
// Already-cleaned products are skipped unless --force is given, so it can be re-run after a failure.
import { readFileSync, writeFileSync, existsSync, renameSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { buildCatalog, normalizeProduct } from './build-catalog.mjs';
import { createGeminiAi } from '../server/ai.js';
import { CONTENT_FIX_SCHEMA, contentFixPrompt } from '../server/prompts.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SOURCE = path.join(root, 'content', 'source', 'seasonal_data.json');
const OVERRIDES = path.join(root, 'content', 'content-overrides.json');
const CATALOG = path.join(root, 'content', 'catalog.json');

const args = Object.fromEntries(
  process.argv.slice(2).map((a) => {
    const [k, v] = a.replace(/^--/, '').split('=');
    return [k, v ?? true];
  }),
);
const model = typeof args.model === 'string' ? args.model : process.env.GEMINI_CONTENT_MODEL || 'gemini-3.8-flash';
const only = typeof args.only === 'string' ? new Set(args.only.split(',')) : null;

const source = JSON.parse(readFileSync(SOURCE, 'utf8'));
const overrides = existsSync(OVERRIDES) ? JSON.parse(readFileSync(OVERRIDES, 'utf8')) : {};
const todo = source.products.filter((p) => (only ? only.has(p.id) : true)).filter((p) => args.force || !overrides[p.id]);

console.log(`${todo.length} product(s) to clean with ${model}${args['dry-run'] ? ' (dry run)' : ''}`);
if (args['dry-run'] || todo.length === 0) process.exit(0);

const ai = createGeminiAi({ apiKey: process.env.GEMINI_API_KEY, textModel: model, imageModel: 'unused' });
if (!ai) {
  console.error('GEMINI_API_KEY is not set');
  process.exit(1);
}

const isBi = (v) => v && typeof v.it === 'string' && typeof v.en === 'string' && v.it.trim() && v.en.trim();

function toOverride(product, result) {
  const ids = new Set(product.stories.map((s) => s.id));
  const stories = {};
  for (const s of result.stories ?? []) if (ids.has(s.id) && isBi(s)) stories[s.id] = { it: s.it.trim(), en: s.en.trim() };
  const out = { stories };
  for (const key of ['name', 'notes', 'kidNote', 'funFact']) if (isBi(result[key])) out[key] = { it: result[key].it.trim(), en: result[key].en.trim() };
  if (typeof result.emoji === 'string' && [...result.emoji.trim()].length <= 4) out.emoji = result.emoji.trim();
  return out;
}

function save() {
  const tmp = `${OVERRIDES}.tmp`;
  writeFileSync(tmp, JSON.stringify(overrides, null, 1) + '\n');
  renameSync(tmp, OVERRIDES);
}

let failed = 0;
for (const [i, raw] of todo.entries()) {
  const product = normalizeProduct(raw);
  process.stdout.write(`[${i + 1}/${todo.length}] ${product.id} … `);
  try {
    const result = await ai.generateJson(contentFixPrompt(product), CONTENT_FIX_SCHEMA, { model });
    overrides[product.id] = toOverride(product, result);
    save();
    console.log(`ok (${Object.keys(overrides[product.id].stories).length}/${product.stories.length} stories)`);
  } catch (err) {
    failed++;
    console.log(`failed: ${err.message}`);
  }
}

const catalog = buildCatalog(source, overrides);
writeFileSync(CATALOG, JSON.stringify(catalog, null, 1) + '\n');
console.log(`Catalog rebuilt with ${Object.keys(overrides).length} override(s). ${failed ? `${failed} failed - re-run to retry.` : 'All done.'}`);
process.exit(failed ? 1 : 0);
