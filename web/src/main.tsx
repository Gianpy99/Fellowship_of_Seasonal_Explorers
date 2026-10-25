import { render } from 'preact';
import { useEffect, useMemo, useState } from 'preact/hooks';
import 'leaflet/dist/leaflet.css';
import '@fontsource-variable/fredoka';
import '@fontsource-variable/nunito';
import './styles.css';
import { api, type Explorer, type ImageIndex, type Lang, type Product } from './api';
import { strings } from './i18n';
import { AppContext, type AppState, useHashRoute, usePersistentState } from './state';
import { ExplorerPicker } from './components/ExplorerPicker';
import { Home } from './components/Home';
import { ProductPage } from './components/ProductPage';
import { BadgesPage } from './components/BadgesPage';
import { TopBar } from './components/TopBar';

const defaultLang: Lang = navigator.language?.toLowerCase().startsWith('it') ? 'it' : 'en';

function App() {
  const [lang, setLang] = usePersistentState<Lang>('sq.lang', defaultLang);
  const [explorerId, setExplorerId] = usePersistentState<string>('sq.explorer', '');
  const [data, setData] = useState<{ products: Product[]; images: ImageIndex; ai: boolean; explorers: Explorer[] } | null>(null);
  const [error, setError] = useState(false);
  const route = useHashRoute();
  const t = strings[lang];

  useEffect(() => {
    document.documentElement.lang = lang;
    document.title = t.appName;
  }, [lang]);

  useEffect(() => {
    Promise.all([api.catalog(), api.me(), api.explorers()])
      .then(([catalog, me, ex]) => setData({ ...catalog, ai: me.ai, explorers: ex.explorers }))
      .catch(() => setError(true));
  }, []);

  const state = useMemo<AppState | null>(() => {
    if (!data) return null;
    const explorer = data.explorers.find((e) => e.id === explorerId);
    if (!explorer) return null;
    return {
      lang,
      setLang,
      t,
      products: data.products,
      byId: new Map(data.products.map((p) => [p.id, p])),
      images: data.images,
      setImage: (pid, slot, version) =>
        setData((d) => d && { ...d, images: { ...d.images, [pid]: { ...d.images[pid], [slot]: version } } }),
      ai: data.ai,
      explorer,
      updateExplorer: (e) => setData((d) => d && { ...d, explorers: d.explorers.map((x) => (x.id === e.id ? e : x)) }),
      switchExplorer: () => setExplorerId(''),
    };
  }, [data, explorerId, lang]);

  if (error) return <div class="center-screen">😿 {t.loadError}</div>;
  if (!data) return <div class="center-screen"><div class="spinner" aria-label={t.loading} /></div>;

  if (!state) {
    return (
      <ExplorerPicker
        lang={lang}
        setLang={setLang}
        explorers={data.explorers}
        onPick={(e) => setExplorerId(e.id)}
        onChange={(explorers) => setData({ ...data, explorers })}
      />
    );
  }

  const [page, id] = route;
  const product = page === 'p' && id ? state.byId.get(id) : undefined;

  return (
    <AppContext.Provider value={state}>
      <TopBar />
      <main class="page">
        {product ? <ProductPage key={product.id} product={product} /> : page === 'badges' ? <BadgesPage /> : <Home />}
      </main>
    </AppContext.Provider>
  );
}

render(<App />, document.getElementById('app')!);
