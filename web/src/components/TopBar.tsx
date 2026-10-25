import type { Lang } from '../api';
import { useApp } from '../state';

export function LangToggle({ lang, setLang }: { lang: Lang; setLang: (l: Lang) => void }) {
  return (
    <div class="lang-toggle" role="group" aria-label="Language">
      <button class={lang === 'it' ? 'is-on' : ''} aria-pressed={lang === 'it'} onClick={() => setLang('it')}>
        IT
      </button>
      <button class={lang === 'en' ? 'is-on' : ''} aria-pressed={lang === 'en'} onClick={() => setLang('en')}>
        EN
      </button>
    </div>
  );
}

export function TopBar() {
  const { t, lang, setLang, explorer, products, switchExplorer } = useApp();
  const done = Object.keys(explorer.completed).length;
  return (
    <header class="topbar">
      <a class="brand" href="#/">
        <span aria-hidden="true">🍋</span> <span class="hide-sm">{t.appName}</span>
      </a>
      <nav class="topbar-actions">
        <a class="pill" href="#/badges" title={t.badges}>
          🏅 <span class="hide-sm">{t.badges}</span>
        </a>
        <div class="progress-pill" title={`${done}/${products.length} ${t.discovered}`}>
          <div class="progress-fill" style={{ width: `${(done / products.length) * 100}%` }} />
          <span>
            ⭐ {done}/{products.length}
          </span>
        </div>
        <LangToggle lang={lang} setLang={setLang} />
        <button class="pill explorer-chip" onClick={switchExplorer} title={t.switchExplorer}>
          <span class="explorer-chip-avatar">{explorer.avatar}</span>
          <span class="hide-sm">{explorer.name}</span>
        </button>
      </nav>
    </header>
  );
}
