import { imageUrl, type Product } from '../api';
import { seasonStatus } from '../lib';
import { useApp } from '../state';

export function ProductIcon({ product, size = 'md' }: { product: Product; size?: 'md' | 'lg' }) {
  const { images } = useApp();
  const version = images[product.id]?.icon;
  return (
    <div class={`product-icon size-${size} cat-bg-${product.category}`}>
      {version ? (
        <img src={imageUrl(product.id, 'icon', version)} alt="" loading="lazy" decoding="async" />
      ) : (
        <span aria-hidden="true">{product.emoji}</span>
      )}
    </div>
  );
}

export function ProductCard({ product, month }: { product: Product; month: number }) {
  const { t, lang, explorer } = useApp();
  const status = seasonStatus(product, month);
  const done = Boolean(explorer.completed[product.id]);
  const label = { harvest: t.harvestNow, shops: t.inShops, off: t.notNow }[status];
  return (
    <a class={`product-card status-${status} ${done ? 'is-done' : ''}`} href={`#/p/${encodeURIComponent(product.id)}`}>
      {done && (
        <span class="done-stamp" title={t.found}>
          ⭐
        </span>
      )}
      <ProductIcon product={product} />
      <div class="product-card-body">
        <h3>{product.name[lang]}</h3>
        <p class="muted">📍 {product.town}</p>
        <span class={`status-tag tag-${status}`}>{label}</span>
      </div>
    </a>
  );
}
