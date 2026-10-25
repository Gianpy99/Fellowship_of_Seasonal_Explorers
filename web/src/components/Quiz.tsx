import { useState } from 'preact/hooks';
import { api, type Product, type Quiz as QuizData } from '../api';
import { useApp } from '../state';
import { aiErrorMessage } from './common';

export function Quiz({ product }: { product: Product }) {
  const { t, lang, explorer, updateExplorer } = useApp();
  const [quiz, setQuiz] = useState<QuizData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [index, setIndex] = useState(0);
  const [picked, setPicked] = useState<number | null>(null);
  const [score, setScore] = useState(0);
  const [finished, setFinished] = useState(false);
  const best = explorer.quizzes[product.id];

  async function start() {
    setLoading(true);
    setError('');
    try {
      const q = quiz?.lang === lang ? quiz : await api.quiz(product.id, lang);
      setQuiz(q);
      setIndex(0);
      setPicked(null);
      setScore(0);
      setFinished(false);
    } catch (err) {
      setError(aiErrorMessage(err, t));
    } finally {
      setLoading(false);
    }
  }

  function pick(i: number) {
    if (picked !== null || !quiz) return;
    setPicked(i);
    if (i === quiz.questions[index].answer) setScore((s) => s + 1);
  }

  async function next() {
    if (!quiz) return;
    if (index + 1 < quiz.questions.length) {
      setIndex(index + 1);
      setPicked(null);
      return;
    }
    setFinished(true);
    try {
      const r = await api.recordQuiz(explorer.id, product.id, score, quiz.questions.length);
      updateExplorer(r.explorer);
    } catch {
      /* the score still shows; saving is best-effort */
    }
  }

  const active = quiz && quiz.lang === lang && !finished;
  const q = active ? quiz.questions[index] : null;

  return (
    <section class="panel quiz">
      <div class="panel-head">
        <h2>🧠 {t.quiz}</h2>
        {best && <span class="muted">{t.bestScore(best.best, best.total)}</span>}
      </div>

      {loading && (
        <p class="loading-line">
          <span class="spinner small" /> {t.preparingQuiz}
        </p>
      )}
      {error && <p class="error">⚠️ {error}</p>}

      {!loading && !active && !finished && (
        <button class="btn primary big" onClick={start}>
          🐦 {t.startQuiz}
        </button>
      )}

      {q && quiz && (
        <div class="quiz-card">
          <div class="quiz-progress">
            {quiz.questions.map((_, i) => (
              <span key={i} class={i < index ? 'done' : i === index ? 'now' : ''} />
            ))}
          </div>
          <h3>{q.question}</h3>
          <div class="quiz-options">
            {q.options.map((o, i) => {
              const state = picked === null ? '' : i === q.answer ? 'right' : i === picked ? 'wrong' : 'dim';
              return (
                <button key={i} class={`quiz-option ${state}`} onClick={() => pick(i)} disabled={picked !== null}>
                  {o}
                </button>
              );
            })}
          </div>
          {picked !== null && (
            <div class={`quiz-feedback ${picked === q.answer ? 'right' : 'wrong'}`}>
              <strong>{picked === q.answer ? t.correct : t.wrong}</strong> {q.explanation}
              <button class="btn primary" onClick={next}>
                {index + 1 < quiz.questions.length ? t.next : t.finish} →
              </button>
            </div>
          )}
        </div>
      )}

      {finished && quiz && (
        <div class="quiz-result">
          <div class="quiz-stars" aria-hidden="true">
            {'⭐'.repeat(score)}
            {'☆'.repeat(quiz.questions.length - score)}
          </div>
          <p>{t.score(score, quiz.questions.length)}</p>
          <button class="btn" onClick={start}>
            🔁 {t.tryAgain}
          </button>
        </div>
      )}
    </section>
  );
}
