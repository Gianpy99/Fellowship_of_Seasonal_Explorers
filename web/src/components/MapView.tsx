import { useEffect, useRef } from 'preact/hooks';
import L from 'leaflet';
import type { Product } from '../api';
import { seasonStatus } from '../lib';
import { go, useApp } from '../state';

const CALABRIA: L.LatLngTuple = [38.95, 16.25];

/** Spreads products that share a town around it so every marker stays clickable. */
function spread(products: Product[]): Map<string, L.LatLngTuple> {
  const byTown = new Map<string, Product[]>();
  for (const p of products) byTown.set(p.town, [...(byTown.get(p.town) ?? []), p]);
  const result = new Map<string, L.LatLngTuple>();
  for (const group of byTown.values()) {
    group.forEach((p, i) => {
      if (group.length === 1) return result.set(p.id, p.coords);
      const angle = (2 * Math.PI * i) / group.length;
      const r = 0.018 + 0.004 * Math.floor(i / 8);
      result.set(p.id, [p.coords[0] + r * Math.sin(angle), p.coords[1] + r * 1.3 * Math.cos(angle)]);
    });
  }
  return result;
}

const escapeHtml = (s: string) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

export function MapView({ products, month }: { products: Product[]; month: number }) {
  const { lang, explorer } = useApp();
  const el = useRef<HTMLDivElement>(null);
  const map = useRef<L.Map | null>(null);
  const layer = useRef<L.LayerGroup | null>(null);

  useEffect(() => {
    if (!el.current) return;
    map.current = L.map(el.current, { zoomControl: true, scrollWheelZoom: true }).setView(CALABRIA, 8);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 17,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map.current);
    layer.current = L.layerGroup().addTo(map.current);
    return () => map.current?.remove();
  }, []);

  useEffect(() => {
    const group = layer.current;
    if (!group || !map.current) return;
    group.clearLayers();
    const positions = spread(products);
    for (const p of products) {
      const status = seasonStatus(p, month);
      const done = explorer.completed[p.id] ? ' is-done' : '';
      const icon = L.divIcon({
        className: '',
        html: `<div class="map-pin pin-${status}${done}" title="${escapeHtml(p.name[lang])}">${p.emoji}</div>`,
        iconSize: [40, 40],
        iconAnchor: [20, 20],
      });
      L.marker(positions.get(p.id)!, { icon, title: p.name[lang], keyboard: true })
        .on('click', () => go(`/p/${encodeURIComponent(p.id)}`))
        .addTo(group);
    }
    if (products.length) map.current.fitBounds(L.latLngBounds([...positions.values()]), { padding: [40, 40], maxZoom: 9 });
  }, [products, month, lang, explorer]);

  return <div class="map" ref={el} />;
}
