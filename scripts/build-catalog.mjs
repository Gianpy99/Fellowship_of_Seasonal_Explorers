// Builds content/catalog.json (the app's content) from the raw story database.
// Usage: node scripts/build-catalog.mjs
// AI text fixes from scripts/clean-content.mjs live in content/content-overrides.json
// and are merged here, so the raw source is never modified.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SOURCE = path.join(root, 'content', 'source', 'seasonal_data.json');
const OVERRIDES = path.join(root, 'content', 'content-overrides.json');
const OUTPUT = path.join(root, 'content', 'catalog.json');

const MONTHS = { Jan: 1, Feb: 2, Mar: 3, Apr: 4, May: 5, Jun: 6, Jul: 7, Aug: 8, Sep: 9, Oct: 10, Nov: 11, Dec: 12 };

export const CATEGORIES = {
  Frutti: 'fruit',
  Verdure: 'vegetable',
  Fiori: 'flower',
  Prodotti_animali: 'animal',
  'Prodotti Animali': 'animal',
  Prodotti_da_pianta: 'plant',
};

const CATEGORY_EMOJI = { fruit: '🍎', vegetable: '🥕', flower: '🌸', animal: '🧀', plant: '🌿' };

// Keyed by the id prefix (before _calabria / _uk) so both regions share an emoji.
const PRODUCT_EMOJI = {
  aglio: '🧄', anguria: '🍉', arancia: '🍊', asparago: '🌱', bergamotto: '🍋', bietola: '🥬', bucaneve: '🤍',
  carota: '🥕', cavolfiore: '🥦', cavolo: '🥬', ciliegia: '🍒', cipolla: '🧅', fagiolino: '🫛', fico: '🟣',
  formaggio_stagionato: '🧀', fragola: '🍓', kiwi: '🥝', lampone: '🍓', latte: '🥛', lavanda: '💜', limone: '🍋',
  mandarino: '🍊', mela: '🍎', melanzana: '🍆', melograno: '🔴', melone: '🍈', miele: '🍯', mirtillo: '🫐',
  more: '🫐', narciso: '🌼', olive: '🫒', pastinaca: '🥕', patata: '🥔', peperone: '🫑', pera: '🍐', pesca: '🍑',
  pisello: '🫛', pomodoro: '🍅', rhubarb: '🌿', ricotta: '🧀', spinacio: '🥬', uova: '🥚', uva: '🍇', verza: '🥬',
  zucca: '🎃', zucchina: '🥒',
};

// The source data gives English products Calabrian towns; place them where they really grow instead.
export const ENGLAND_TOWNS = {
  Evesham: [52.0921, -1.9469],
  Painswick: [51.7869, -2.1946],
  Chichester: [50.8365, -0.7792],
  Canterbury: [51.2802, 1.0789],
  Faversham: [51.3159, 0.8892],
  Cheddar: [51.2795, -2.7781],
  Hitchin: [51.9488, -0.2829],
  Winchester: [51.0632, -1.308],
  Dorchester: [50.7154, -2.4367],
  Lyndhurst: [50.8722, -1.5753],
  Truro: [50.2632, -5.051],
  'Isle of Wight': [50.6723, -1.2346],
  Salisbury: [51.0688, -1.7945],
};

const ENGLAND_PLACEMENT = {
  asparago_uk: 'Evesham', bucaneve_uk: 'Painswick', carota_uk: 'Chichester', cavolo_uk: 'Chichester',
  fragola_uk: 'Canterbury', lampone_uk: 'Canterbury', latte_uk: 'Cheddar', lavanda_uk: 'Hitchin',
  mela_uk: 'Faversham', pera_uk: 'Faversham', miele_uk: 'Winchester', rhubarb_uk: 'Winchester',
  mirtillo_uk: 'Dorchester', more_uk: 'Lyndhurst', narciso_uk: 'Truro', patata_uk: 'Truro',
  pastinaca_uk: 'Chichester', pisello_uk: 'Canterbury', pomodoro_uk: 'Isle of Wight', uova_uk: 'Salisbury',
};

export const TOWNS = {
  'Reggio Calabria': [38.1113, 15.6475],
  Siderno: [38.2686, 16.2989],
  Locri: [38.2357, 16.2625],
  Polistena: [38.4014, 16.0778],
  'Bagnara Calabra': [38.2847, 15.8067],
  Scilla: [38.2503, 15.7167],
  Tropea: [38.6736, 15.8983],
  'Pizzo Calabro': [38.7344, 16.1681],
  Catanzaro: [38.9094, 16.5877],
  'Lamezia Terme': [38.966, 16.31],
  Soverato: [38.6872, 16.5511],
  'Serra San Bruno': [38.5761, 16.3289],
  Cosenza: [39.2986, 16.2517],
  Rossano: [39.5767, 16.6358],
  'Belvedere Marittimo': [39.6211, 15.8631],
  Scalea: [39.8136, 15.7908],
  Amantea: [39.1392, 16.0744],
  Diamante: [39.6825, 15.8222],
  Sibari: [39.7458, 16.4939],
};

const toMonths = (list = []) => [...new Set(list.map((m) => MONTHS[m]).filter(Boolean))].sort((a, b) => a - b);

function pairs(itList = [], enList = []) {
  return itList.map((it, i) => ({ it, en: enList[i] ?? it }));
}

export function normalizeProduct(raw, override = {}) {
  const category = CATEGORIES[raw.category];
  if (!category) throw new Error(`Unknown category "${raw.category}" for ${raw.id}`);
  const region = raw.id.endsWith('_uk') ? 'england' : 'calabria';
  let town;
  let coords;
  if (region === 'england') {
    town = ENGLAND_PLACEMENT[raw.id] ?? 'Winchester';
    coords = ENGLAND_TOWNS[town];
  } else {
    town = TOWNS[raw.local_town] ? raw.local_town : 'Reggio Calabria';
    coords = TOWNS[town];
  }
  const emoji = PRODUCT_EMOJI[raw.id.replace(/_(calabria|uk)$/, '')] ?? CATEGORY_EMOJI[category];

  const stories = [
    ...pairs(raw.story?.it, raw.story?.en).map((text, i) => ({ id: `adv-${i + 1}`, region: 'calabria', kind: 'adventure', text })),
    ...(raw.stories?.Calabria ?? []).map((text, i) => ({ id: `cal-${i + 1}`, region: 'calabria', kind: 'tale', text })),
    ...(raw.stories?.['Bassa Inghilterra'] ?? []).map((text, i) => ({ id: `eng-${i + 1}`, region: 'england', kind: 'tale', text })),
  ];

  const product = {
    id: raw.id,
    name: { it: raw.it, en: raw.en },
    category,
    region,
    emoji,
    harvestMonths: toMonths(raw.harvest_months),
    shelfMonths: toMonths(raw.shelf_months),
    yearRound: Boolean(raw.available_year_round),
    notes: { it: raw.notes_it, en: raw.notes_en },
    kidNote: { it: raw.kid_note_it ?? raw.notes_it, en: raw.kid_note_en ?? raw.notes_en },
    town,
    coords,
    stories,
  };

  return applyOverride(product, override);
}

function applyOverride(product, override) {
  if (!override || typeof override !== 'object') return product;
  const merged = { ...product };
  for (const key of ['name', 'notes', 'kidNote']) {
    if (override[key]) merged[key] = { ...product[key], ...override[key] };
  }
  if (typeof override.emoji === 'string' && override.emoji.trim()) merged.emoji = override.emoji.trim();
  if (override.funFact) merged.funFact = override.funFact;
  if (override.stories) {
    merged.stories = product.stories.map((s) => (override.stories[s.id] ? { ...s, text: { ...s.text, ...override.stories[s.id] } } : s));
  }
  return merged;
}

export function buildCatalog(source, overrides = {}) {
  const products = source.products.map((p) => normalizeProduct(p, overrides[p.id]));
  products.sort((a, b) => a.name.it.localeCompare(b.name.it, 'it'));
  return { version: 2, products };
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const source = JSON.parse(readFileSync(SOURCE, 'utf8'));
  const overrides = existsSync(OVERRIDES) ? JSON.parse(readFileSync(OVERRIDES, 'utf8')) : {};
  const catalog = buildCatalog(source, overrides);
  writeFileSync(OUTPUT, JSON.stringify(catalog, null, 1) + '\n');
  const counts = catalog.products.reduce((acc, p) => ((acc[p.category] = (acc[p.category] ?? 0) + 1), acc), {});
  console.log(`Wrote ${catalog.products.length} products to ${path.relative(root, OUTPUT)}`, counts, `overrides: ${Object.keys(overrides).length}`);
}
