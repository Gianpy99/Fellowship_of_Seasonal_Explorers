import { useState } from 'preact/hooks';
import { api, imageUrl, type Product, type Story } from '../api';
import { useApp } from '../state';
import { aiErrorMessage, ReadAloud } from './common';

function StoryCard({ product, story }: { product: Product; story: Story }) {
  const { t, lang, images, setImage, ai } = useApp();
  const version = images[product.id]?.[story.id];
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const text = story.text[lang];

  async function paint(redo: boolean) {
    setBusy(true);
    setError('');
    try {
      const r = await api.generateImage(product.id, story.id, redo);
      setImage(product.id, story.id, r.version);
    } catch (err) {
      setError(aiErrorMessage(err, t));
    } finally {
      setBusy(false);
    }
  }

  return (
    <article class="story-card">
      <div class="story-art">
        {busy ? (
          <div class="painting">
            <div class="brush" aria-hidden="true">🖌️</div>
            <p>{t.painting}</p>
          </div>
        ) : version ? (
          <>
            <img src={imageUrl(product.id, story.id, version)} alt="" loading="lazy" decoding="async" />
            {ai && (
              <button class="repaint" onClick={() => paint(true)} title={t.repaint}>
                🔄 {t.repaint}
              </button>
            )}
          </>
        ) : ai ? (
          <button class="paint-btn" onClick={() => paint(false)}>
            <span aria-hidden="true">🎨</span>
            {t.paint}
          </button>
        ) : (
          <div class="painting">
            <span aria-hidden="true">{product.emoji}</span>
          </div>
        )}
      </div>
      {error && <p class="error">⚠️ {error}</p>}
      <div class="story-text">
        <p>{text}</p>
        <ReadAloud text={text} lang={lang} />
      </div>
    </article>
  );
}

const GROUPS = [
  { key: 'adventure', match: (s: Story) => s.kind === 'adventure', label: 'adventures' },
  { key: 'calabria', match: (s: Story) => s.kind === 'tale' && s.region === 'calabria', label: 'calabriaTales' },
  { key: 'england', match: (s: Story) => s.kind === 'tale' && s.region === 'england', label: 'englandTales' },
] as const;

export function Stories({ product }: { product: Product }) {
  const { t } = useApp();
  const groups = GROUPS.filter((g) => product.stories.some(g.match));
  const [tab, setTab] = useState<string>(groups[0]?.key ?? 'adventure');
  const active = groups.find((g) => g.key === tab) ?? groups[0];
  if (!active) return null;
  return (
    <section class="panel">
      <h2>📖 {t.stories}</h2>
      <div class="tabs" role="tablist">
        {groups.map((g) => (
          <button key={g.key} role="tab" aria-selected={g.key === active.key} class={g.key === active.key ? 'is-on' : ''} onClick={() => setTab(g.key)}>
            {t[g.label]}
          </button>
        ))}
      </div>
      <div class="story-list">
        {product.stories.filter(active.match).map((s) => (
          <StoryCard key={s.id} product={product} story={s} />
        ))}
      </div>
    </section>
  );
}
