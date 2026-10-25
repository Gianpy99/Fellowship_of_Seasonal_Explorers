import type { Bi, Category, Explorer, Lang, Product } from './api';

export type SeasonStatus = 'harvest' | 'shops' | 'off';

export function seasonStatus(p: Product, month: number): SeasonStatus {
  if (p.harvestMonths.includes(month)) return 'harvest';
  if (p.yearRound || p.shelfMonths.includes(month)) return 'shops';
  return 'off';
}

export const SEASONS = {
  winter: [12, 1, 2],
  spring: [3, 4, 5],
  summer: [6, 7, 8],
  autumn: [9, 10, 11],
} as const;

export type Season = keyof typeof SEASONS;

export const seasonOf = (month: number): Season =>
  (Object.keys(SEASONS) as Season[]).find((s) => (SEASONS[s] as readonly number[]).includes(month)) ?? 'spring';

export const CATEGORY_ORDER: Category[] = ['fruit', 'vegetable', 'flower', 'animal', 'plant'];

export interface BadgeDef {
  id: string;
  icon: string;
  name: Bi;
  description: Bi;
  goal: number;
  progress: (products: Product[], explorer: Explorer) => number;
}

const completedProducts = (products: Product[], e: Explorer) => products.filter((p) => e.completed[p.id]);
const countCategory = (products: Product[], e: Explorer, c: Category) => completedProducts(products, e).filter((p) => p.category === c).length;
const countSeason = (products: Product[], e: Explorer, s: Season) =>
  completedProducts(products, e).filter((p) => p.harvestMonths.some((m) => (SEASONS[s] as readonly number[]).includes(m))).length;

export const BADGES: BadgeDef[] = [
  { id: 'first', icon: '🌱', goal: 1, name: { it: 'Primo passo', en: 'First step' }, description: { it: 'Scopri il tuo primo prodotto', en: 'Discover your first product' }, progress: (p, e) => completedProducts(p, e).length },
  { id: 'spring', icon: '🌸', goal: 3, name: { it: 'Esploratore di primavera', en: 'Spring explorer' }, description: { it: '3 prodotti che si raccolgono in primavera', en: '3 products harvested in spring' }, progress: (p, e) => countSeason(p, e, 'spring') },
  { id: 'summer', icon: '☀️', goal: 3, name: { it: "Esploratore d'estate", en: 'Summer explorer' }, description: { it: '3 prodotti che si raccolgono in estate', en: '3 products harvested in summer' }, progress: (p, e) => countSeason(p, e, 'summer') },
  { id: 'autumn', icon: '🍂', goal: 3, name: { it: "Esploratore d'autunno", en: 'Autumn explorer' }, description: { it: '3 prodotti che si raccolgono in autunno', en: '3 products harvested in autumn' }, progress: (p, e) => countSeason(p, e, 'autumn') },
  { id: 'winter', icon: '❄️', goal: 3, name: { it: "Esploratore d'inverno", en: 'Winter explorer' }, description: { it: "3 prodotti che si raccolgono d'inverno", en: '3 products harvested in winter' }, progress: (p, e) => countSeason(p, e, 'winter') },
  { id: 'fruit', icon: '🍎', goal: 5, name: { it: 'Raccoglitore di frutta', en: 'Fruit collector' }, description: { it: 'Scopri 5 frutti', en: 'Discover 5 fruits' }, progress: (p, e) => countCategory(p, e, 'fruit') },
  { id: 'veg', icon: '🥕', goal: 5, name: { it: "Amico dell'orto", en: 'Veg patch friend' }, description: { it: 'Scopri 5 verdure', en: 'Discover 5 vegetables' }, progress: (p, e) => countCategory(p, e, 'vegetable') },
  { id: 'farm', icon: '🐐', goal: 3, name: { it: 'Amico della fattoria', en: 'Farm friend' }, description: { it: 'Scopri 3 prodotti della fattoria', en: 'Discover 3 farm products' }, progress: (p, e) => countCategory(p, e, 'animal') },
  { id: 'flowers', icon: '🌼', goal: 3, name: { it: 'Pollice verde', en: 'Green thumb' }, description: { it: 'Scopri 3 fiori o piante', en: 'Discover 3 flowers or plants' }, progress: (p, e) => countCategory(p, e, 'flower') + countCategory(p, e, 'plant') },
  { id: 'quiz', icon: '🧠', goal: 5, name: { it: 'Genio dei quiz', en: 'Quiz whiz' }, description: { it: '5 quiz perfetti', en: '5 perfect quizzes' }, progress: (_p, e) => Object.values(e.quizzes).filter((q) => q.best === q.total).length },
  { id: 'towns', icon: '🗺️', goal: 6, name: { it: 'Piccolo giramondo', en: 'Little globetrotter' }, description: { it: 'Prodotti da 6 paesi diversi', en: 'Products from 6 different towns' }, progress: (p, e) => new Set(completedProducts(p, e).map((x) => x.town)).size },
  { id: 'master', icon: '🏆', goal: Number.POSITIVE_INFINITY, name: { it: 'Maestro delle stagioni', en: 'Master of seasons' }, description: { it: 'Scopri tutto!', en: 'Discover everything!' }, progress: (p, e) => completedProducts(p, e).length },
];

export function badgeStatus(products: Product[], explorer: Explorer) {
  return BADGES.map((b) => {
    const goal = Number.isFinite(b.goal) ? b.goal : products.length;
    const value = Math.min(b.progress(products, explorer), goal);
    return { ...b, goal, value, unlocked: value >= goal };
  });
}

// ---- Read aloud with the browser's built-in voices (free, offline)
let speaking: SpeechSynthesisUtterance | null = null;

export const canSpeak = () => typeof window !== 'undefined' && 'speechSynthesis' in window;

export function speak(text: string, lang: Lang, onEnd?: () => void) {
  if (!canSpeak()) return;
  window.speechSynthesis.cancel();
  const u = new SpeechSynthesisUtterance(text.replace(/\p{Extended_Pictographic}/gu, ''));
  u.lang = lang === 'it' ? 'it-IT' : 'en-GB';
  const voice = window.speechSynthesis.getVoices().find((v) => v.lang.toLowerCase().startsWith(u.lang.toLowerCase().slice(0, 2)));
  if (voice) u.voice = voice;
  u.rate = 0.92;
  u.pitch = 1.05;
  u.onend = u.onerror = () => {
    if (speaking === u) speaking = null;
    onEnd?.();
  };
  speaking = u;
  window.speechSynthesis.speak(u);
}

export function stopSpeaking() {
  if (canSpeak()) window.speechSynthesis.cancel();
  speaking = null;
}

export const streetViewUrl = ([lat, lng]: [number, number]) =>
  `https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${lat},${lng}`;
export const mapsUrl = ([lat, lng]: [number, number], query: string) =>
  `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(query)}&center=${lat},${lng}`;
