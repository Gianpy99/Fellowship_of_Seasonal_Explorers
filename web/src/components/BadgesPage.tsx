import { badgeStatus } from '../lib';
import { useApp } from '../state';

export function BadgesPage() {
  const { t, lang, products, explorer } = useApp();
  const badges = badgeStatus(products, explorer);
  const unlocked = badges.filter((b) => b.unlocked).length;
  return (
    <div class="badges-page">
      <a class="back-link" href="#/">
        ← {t.back}
      </a>
      <h1>
        🏅 {t.badges} <small class="muted">{unlocked}/{badges.length}</small>
      </h1>
      <div class="badge-grid">
        {badges.map((b) => (
          <div key={b.id} class={`badge ${b.unlocked ? 'is-on' : ''}`}>
            <div class="badge-icon" aria-hidden="true">
              {b.icon}
            </div>
            <h3>{b.name[lang]}</h3>
            <p>{b.description[lang]}</p>
            <div class="badge-bar" role="progressbar" aria-valuenow={b.value} aria-valuemax={b.goal}>
              <div style={{ width: `${(b.value / b.goal) * 100}%` }} />
            </div>
            <small>{b.unlocked ? '✅' : `${b.value}/${b.goal} · ${t.badgeLocked}`}</small>
          </div>
        ))}
      </div>
    </div>
  );
}
