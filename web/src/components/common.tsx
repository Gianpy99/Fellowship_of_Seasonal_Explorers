import { useEffect, useState } from 'preact/hooks';
import { ApiError, type Lang } from '../api';
import { canSpeak, speak, stopSpeaking } from '../lib';
import { useApp } from '../state';

export function aiErrorMessage(err: unknown, t: ReturnType<typeof useApp>['t']): string {
  if (err instanceof ApiError) {
    if (err.code === 'ai_disabled') return t.aiOff;
    if (err.code === 'daily_limit') return t.aiLimit;
  }
  return t.aiFailed;
}

export function ReadAloud({ text, lang }: { text: string; lang: Lang }) {
  const { t } = useApp();
  const [on, setOn] = useState(false);
  useEffect(() => () => on && stopSpeaking(), [on]);
  if (!canSpeak()) return null;
  return (
    <button
      class={`icon-btn ${on ? 'is-on' : ''}`}
      title={on ? t.stop : t.readAloud}
      aria-label={on ? t.stop : t.readAloud}
      onClick={() => {
        if (on) {
          stopSpeaking();
          setOn(false);
        } else {
          setOn(true);
          speak(text, lang, () => setOn(false));
        }
      }}
    >
      {on ? '⏹️' : '🔊'}
    </button>
  );
}
