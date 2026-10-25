import { useState } from 'preact/hooks';
import { api, ApiError, type Explorer, type Lang } from '../api';
import { strings } from '../i18n';
import { LangToggle } from './TopBar';

const AVATARS = ['🦊', '🐰', '🦉', '🐢', '🐝', '🦔', '🐸', '🦋', '🐞', '🐿️'];

interface Props {
  lang: Lang;
  setLang: (l: Lang) => void;
  explorers: Explorer[];
  onPick: (e: Explorer) => void;
  onChange: (explorers: Explorer[]) => void;
}

export function ExplorerPicker({ lang, setLang, explorers, onPick, onChange }: Props) {
  const t = strings[lang];
  const [creating, setCreating] = useState(explorers.length === 0);
  const [name, setName] = useState('');
  const [avatar, setAvatar] = useState(AVATARS[explorers.length % AVATARS.length]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function create(e: Event) {
    e.preventDefault();
    if (!name.trim()) return;
    setBusy(true);
    setError('');
    try {
      const { explorer } = await api.addExplorer(name.trim(), avatar);
      onChange([...explorers, explorer]);
      onPick(explorer);
    } catch (err) {
      setError(err instanceof ApiError ? err.code : 'error');
    } finally {
      setBusy(false);
    }
  }

  async function remove(ex: Explorer) {
    if (!confirm(t.confirmRemove(ex.name))) return;
    await api.removeExplorer(ex.id);
    onChange(explorers.filter((x) => x.id !== ex.id));
  }

  return (
    <div class="picker">
      <div class="picker-lang">
        <LangToggle lang={lang} setLang={setLang} />
      </div>
      <div class="picker-hero">
        <div class="picker-logo" aria-hidden="true">🍋🌿🐦</div>
        <h1>{t.appName}</h1>
        <p>{t.tagline}</p>
      </div>

      {!creating && (
        <section class="picker-card">
          <h2>{t.whoIsExploring}</h2>
          <div class="explorer-grid">
            {explorers.map((ex) => (
              <div class="explorer-tile" key={ex.id}>
                <button class="explorer-pick" onClick={() => onPick(ex)}>
                  <span class="explorer-avatar">{ex.avatar}</span>
                  <span class="explorer-name">{ex.name}</span>
                  <span class="explorer-count">⭐ {Object.keys(ex.completed).length}</span>
                </button>
                <button class="explorer-remove" title={t.remove} aria-label={`${t.remove} ${ex.name}`} onClick={() => remove(ex)}>
                  ✕
                </button>
              </div>
            ))}
            {explorers.length < 8 && (
              <button class="explorer-pick explorer-new" onClick={() => setCreating(true)}>
                <span class="explorer-avatar">➕</span>
                <span class="explorer-name">{t.newExplorer}</span>
              </button>
            )}
          </div>
        </section>
      )}

      {creating && (
        <form class="picker-card" onSubmit={create}>
          <h2>{t.newExplorer}</h2>
          <label class="field">
            <span>{t.yourName}</span>
            <input value={name} maxLength={24} autoFocus onInput={(e) => setName(e.currentTarget.value)} />
          </label>
          <span class="field-label">{t.chooseAvatar}</span>
          <div class="avatar-row" role="radiogroup">
            {AVATARS.map((a) => (
              <button type="button" role="radio" aria-checked={a === avatar} class={`avatar-choice ${a === avatar ? 'is-on' : ''}`} onClick={() => setAvatar(a)}>
                {a}
              </button>
            ))}
          </div>
          {error && <p class="error">⚠️ {error}</p>}
          <div class="row gap">
            {explorers.length > 0 && (
              <button type="button" class="btn ghost" onClick={() => setCreating(false)}>
                {t.back}
              </button>
            )}
            <button class="btn primary big" disabled={busy || !name.trim()}>
              {avatar} {t.start}
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
