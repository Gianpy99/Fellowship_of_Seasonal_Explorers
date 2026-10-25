import { useEffect, useRef, useState } from 'preact/hooks';
import L from 'leaflet';
import { api, type Product } from '../api';
import { mapsUrl, seasonStatus, streetViewUrl } from '../lib';
import { useApp } from '../state';
import { aiErrorMessage, ReadAloud } from './common';
import { ProductIcon } from './ProductCard';
import { Stories } from './Stories';
import { Quiz } from './Quiz';
import { NonnaChat } from './NonnaChat';

function Calendar({ product }: { product: Product }) {
  const { t } = useApp();
  const now = new Date().getMonth() + 1;
  return (
    <section class="panel">
      <h2>📅 {t.calendar}</h2>
      <div class="calendar">
        {t.months.map((m, i) => {
          const status = seasonStatus(product, i + 1);
          return (
            <div key={m} class={`cal-cell cal-${status} ${i + 1 === now ? 'is-now' : ''}`} title={`${m}`}>
              <span>{t.monthsShort[i]}</span>
            </div>
          );
        })}
      </div>
      <div class="legend">
        <span>
          <i class="dot cal-harvest" /> {t.harvest}
        </span>
        <span>
          <i class="dot cal-shops" /> {t.shops}
        </span>
      </div>
    </section>
  );
}

function MiniMap({ product }: { product: Product }) {
  const el = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!el.current) return;
    const map = L.map(el.current, { zoomControl: false, attributionControl: true, scrollWheelZoom: false }).setView(product.coords, 11);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 17,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map);
    L.marker(product.coords, {
      icon: L.divIcon({ className: '', html: `<div class="map-pin pin-harvest">${product.emoji}</div>`, iconSize: [40, 40], iconAnchor: [20, 20] }),
    }).addTo(map);
    return () => map.remove();
  }, [product.id]);
  return <div class="mini-map" ref={el} />;
}

export function ProductPage({ product }: { product: Product }) {
  const { t, lang, explorer, updateExplorer, images, setImage, ai } = useApp();
  const name = product.name[lang];
  const done = Boolean(explorer.completed[product.id]);
  const [busy, setBusy] = useState(false);
  const [paintingIcon, setPaintingIcon] = useState(false);
  const [error, setError] = useState('');
  const status = seasonStatus(product, new Date().getMonth() + 1);

  async function toggleDone() {
    setBusy(true);
    try {
      const r = await api.setCompleted(explorer.id, product.id, !done);
      updateExplorer(r.explorer);
      if (!done) celebrate();
    } finally {
      setBusy(false);
    }
  }

  async function paintIcon() {
    setPaintingIcon(true);
    setError('');
    try {
      const r = await api.generateImage(product.id, 'icon', Boolean(images[product.id]?.icon));
      setImage(product.id, 'icon', r.version);
    } catch (err) {
      setError(aiErrorMessage(err, t));
    } finally {
      setPaintingIcon(false);
    }
  }

  return (
    <div class={`product-page cat-${product.category}`}>
      <a class="back-link" href="#/">
        ← {t.back}
      </a>

      <section class="product-hero">
        <div class="hero-icon">
          {paintingIcon ? (
            <div class="product-icon size-lg painting">
              <span class="brush">🖌️</span>
            </div>
          ) : (
            <ProductIcon product={product} size="lg" />
          )}
          {ai && (
            <button class="paint-small" onClick={paintIcon} disabled={paintingIcon}>
              {images[product.id]?.icon ? `🔄 ${t.repaint}` : t.paintIcon}
            </button>
          )}
        </div>
        <div class="hero-text">
          <span class={`status-tag tag-${status}`}>{{ harvest: t.harvestNow, shops: t.inShops, off: t.notNow }[status]}</span>
          <h1>{name}</h1>
          <p class="muted">
            {t.categories[product.category]} · 📍 {product.town}
          </p>
          {error && <p class="error">⚠️ {error}</p>}
          <button class={`btn big ${done ? 'success' : 'primary'}`} onClick={toggleDone} disabled={busy}>
            {done ? `⭐ ${t.found} · ${t.undo}` : t.iFoundIt}
          </button>
        </div>
      </section>

      <div class="product-columns">
        <div class="col">
          <section class="panel note">
            <div class="panel-head">
              <h2>💡 {t.kidNote}</h2>
              <ReadAloud text={product.kidNote[lang]} lang={lang} />
            </div>
            <p>{product.kidNote[lang]}</p>
            {product.notes[lang] && product.notes[lang] !== product.kidNote[lang] && <p class="muted">{product.notes[lang]}</p>}
          </section>
          {product.funFact && (
            <section class="panel fact">
              <div class="panel-head">
                <h2>🤓 {t.funFact}</h2>
                <ReadAloud text={product.funFact[lang]} lang={lang} />
              </div>
              <p>{product.funFact[lang]}</p>
            </section>
          )}
          <Calendar product={product} />
          <section class="panel">
            <h2>🧭 {t.explore}</h2>
            <MiniMap product={product} />
            <div class="row gap wrap">
              <a class="btn" href={streetViewUrl(product.coords)} target="_blank" rel="noopener noreferrer">
                🚶 {t.streetView}
              </a>
              <a class="btn ghost" href={mapsUrl(product.coords, `${product.town}, ${product.region === 'england' ? 'England' : 'Calabria'}`)} target="_blank" rel="noopener noreferrer">
                🗺️ {t.openMap}
              </a>
            </div>
          </section>
        </div>
        <div class="col wide">
          <Stories product={product} />
          {ai && <Quiz product={product} />}
          {ai && <NonnaChat product={product} />}
        </div>
      </div>
    </div>
  );
}

function celebrate() {
  const root = document.createElement('div');
  root.className = 'confetti';
  root.setAttribute('aria-hidden', 'true');
  const bits = ['⭐', '🍋', '🌸', '🍇', '🌿', '✨'];
  for (let i = 0; i < 28; i++) {
    const s = document.createElement('span');
    s.textContent = bits[i % bits.length];
    s.style.left = `${Math.random() * 100}%`;
    s.style.animationDelay = `${Math.random() * 0.4}s`;
    s.style.fontSize = `${18 + Math.random() * 22}px`;
    root.appendChild(s);
  }
  document.body.appendChild(root);
  setTimeout(() => root.remove(), 2200);
}
