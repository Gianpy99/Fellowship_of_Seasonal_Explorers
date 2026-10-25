import { createContext } from 'preact';
import { useContext, useEffect, useState } from 'preact/hooks';
import type { Explorer, ImageIndex, Lang, Product } from './api';
import type { Strings } from './i18n';

export interface AppState {
  lang: Lang;
  setLang: (l: Lang) => void;
  t: Strings;
  products: Product[];
  byId: Map<string, Product>;
  images: ImageIndex;
  setImage: (pid: string, slot: string, version: number) => void;
  ai: boolean;
  explorer: Explorer;
  updateExplorer: (e: Explorer) => void;
  switchExplorer: () => void;
}

export const AppContext = createContext<AppState | null>(null);

export function useApp(): AppState {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('AppContext missing');
  return ctx;
}

export function useHashRoute(): string[] {
  const read = () => window.location.hash.replace(/^#\/?/, '').split('/').filter(Boolean).map(decodeURIComponent);
  const [route, setRoute] = useState(read);
  useEffect(() => {
    const onChange = () => {
      setRoute(read());
      window.scrollTo({ top: 0 });
    };
    window.addEventListener('hashchange', onChange);
    return () => window.removeEventListener('hashchange', onChange);
  }, []);
  return route;
}

export const go = (path: string) => {
  window.location.hash = path;
};

export function usePersistentState<T extends string>(key: string, initial: T): [T, (v: T) => void] {
  const [value, setValue] = useState<T>(() => (localStorage.getItem(key) as T | null) ?? initial);
  return [
    value,
    (v: T) => {
      localStorage.setItem(key, v);
      setValue(v);
    },
  ];
}
