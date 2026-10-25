import { useEffect, useRef, useState } from 'preact/hooks';
import { api, type ChatMessage, type Product } from '../api';
import { useApp } from '../state';
import { aiErrorMessage, ReadAloud } from './common';

export function NonnaChat({ product }: { product: Product }) {
  const { t, lang } = useApp();
  const name = product.name[lang];
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const log = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setMessages([]);
    setError('');
  }, [lang]);

  useEffect(() => {
    log.current?.scrollTo({ top: log.current.scrollHeight, behavior: 'smooth' });
  }, [messages, busy]);

  async function send(text: string) {
    const clean = text.trim().slice(0, 400);
    if (!clean || busy) return;
    const next: ChatMessage[] = [...messages, { role: 'user', text: clean }];
    setMessages(next);
    setInput('');
    setBusy(true);
    setError('');
    try {
      const { reply } = await api.chat(product.id, lang, next.slice(-12));
      setMessages([...next, { role: 'nonna', text: reply }]);
    } catch (err) {
      setError(aiErrorMessage(err, t));
    } finally {
      setBusy(false);
    }
  }

  return (
    <section class="panel chat">
      <h2>👵 {t.askNonna}</h2>
      <div class="chat-log" ref={log} aria-live="polite">
        <div class="bubble nonna">{t.nonnaHello(name)}</div>
        {messages.map((m, i) => (
          <div key={i} class={`bubble ${m.role}`}>
            {m.text}
            {m.role === 'nonna' && <ReadAloud text={m.text} lang={lang} />}
          </div>
        ))}
        {busy && (
          <div class="bubble nonna typing" aria-label="…">
            <span />
            <span />
            <span />
          </div>
        )}
      </div>
      {error && <p class="error">⚠️ {error}</p>}
      {messages.length === 0 && (
        <div class="chips">
          {t.suggestions(name).map((s) => (
            <button key={s} class="chip" onClick={() => send(s)} disabled={busy}>
              {s}
            </button>
          ))}
        </div>
      )}
      <form
        class="chat-input"
        onSubmit={(e) => {
          e.preventDefault();
          send(input);
        }}
      >
        <input value={input} maxLength={400} placeholder={t.chatPlaceholder} onInput={(e) => setInput(e.currentTarget.value)} disabled={busy} />
        <button class="btn primary" disabled={busy || !input.trim()}>
          {t.send}
        </button>
      </form>
    </section>
  );
}
