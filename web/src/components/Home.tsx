import { useMemo, useState } from 'preact/hooks';
import type { Category } from '../api';
import { CATEGORY_ORDER, seasonOf, seasonStatus } from '../lib';
import { useApp, usePersistentState } from '../state';
import { ProductCard } from './ProductCard';
import { MapView } from './MapView';

const SEASON_EMOJI = { winter: '❄️', spring: '🌸', summer: '☀️', autumn: '🍂' };

export function Home() {
  const { t, lang, products } = useApp();
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const [category, setCategory] = useState<Category | 'all'>('all');
  const [onlySeason, setOnlySeason] = usePersistentState<'1' | '0'>('sq.onlySeason', '1');
  const [view, setView] = usePersistentState<'cards' | 'map'>('sq.view', 'cards');
  const [region, setRegion] = usePersistentState<'all' | 'calabria' | 'england'>('sq.region', 'all');
  const [query, setQuery] = useState('');
  const season = seasonOf(month);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    const rank = { harvest: 0, shops: 1, off: 2 };
    return products
      .filter((p) => category === 'all' || p.category === category)
      .filter((p) => region === 'all' || p.region === region)
      .filter((p) => onlySeason === '0' || seasonStatus(p, month) !== 'off')
      .filter((p) => !q || p.name.it.toLowerCase().includes(q) || p.name.en.toLowerCase().includes(q) || p.town.toLowerCase().includes(q))
      .sort((a, b) => rank[seasonStatus(a, month)] - rank[seasonStatus(b, month)] || a.name[lang].localeCompare(b.name[lang], lang));
  }, [products, category, region, onlySeason, month, query, lang]);

  const harvestCount = products.filter((p) => seasonStatus(p, month) === 'harvest').length;
  const shift = (d: number) => setMonth(((month - 1 + d + 12) % 12) + 1);

  return (
    <div class={`home season-${season}`}>
      <section class="season-hero">
        <button class="round-btn" onClick={() => shift(-1)} aria-label="Previous month">
          ◀
        </button>
        <div class="season-title">
          <span class="season-emoji" aria-hidden="true">{SEASON_EMOJI[season]}</span>
          <div>
            <small>{t.inSeasonIn}</small>
            <h1>{t.months[month - 1]}</h1>
            <p>
              🌾 {harvestCount} · {t.harvestNow}
            </p>
          </div>
        </div>
        <button class="round-btn" onClick={() => shift(1)} aria-label="Next month">
          ▶
        </button>
      </section>

      <section class="toolbar">
        <div class="chips" role="group">
          <button class={`chip ${category === 'all' ? 'is-on' : ''}`} onClick={() => setCategory('all')}>
            {t.all}
          </button>
          {CATEGORY_ORDER.map((c) => (
            <button key={c} class={`chip cat-${c} ${category === c ? 'is-on' : ''}`} onClick={() => setCategory(c)}>
              {t.categories[c]}
            </button>
          ))}
        </div>
        <div class="toolbar-right">
          <div class="segmented" role="group">
            {(['all', 'calabria', 'england'] as const).map((r) => (
              <button key={r} class={region === r ? 'is-on' : ''} aria-pressed={region === r} onClick={() => setRegion(r)}>
                {t.regions[r]}
              </button>
            ))}
          </div>
          <input class="search" type="search" placeholder={t.search} value={query} onInput={(e) => setQuery(e.currentTarget.value)} />
          <label class="switch">
            <input type="checkbox" checked={onlySeason === '1'} onChange={(e) => setOnlySeason(e.currentTarget.checked ? '1' : '0')} />
            <span>{t.onlyInSeason}</span>
          </label>
          <div class="segmented" role="group">
            <button class={view === 'cards' ? 'is-on' : ''} onClick={() => setView('cards')}>
              🃏 {t.cards}
            </button>
            <button class={view === 'map' ? 'is-on' : ''} onClick={() => setView('map')}>
              🗺️ {t.map}
            </button>
          </div>
        </div>
      </section>

      {visible.length === 0 ? (
        <p class="empty">🔍 {t.noResults}</p>
      ) : view === 'map' ? (
        <MapView products={visible} month={month} />
      ) : (
        <div class="card-grid">
          {visible.map((p) => (
            <ProductCard key={p.id} product={p} month={month} />
          ))}
        </div>
      )}
    </div>
  );
}
