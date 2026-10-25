export type Lang = 'it' | 'en';
export type Bi = { it: string; en: string };
export type Category = 'fruit' | 'vegetable' | 'flower' | 'animal' | 'plant';

export interface Story {
  id: string;
  region: 'calabria' | 'england';
  kind: 'adventure' | 'tale';
  text: Bi;
}

export interface Product {
  id: string;
  name: Bi;
  category: Category;
  region: 'calabria' | 'england';
  emoji: string;
  harvestMonths: number[];
  shelfMonths: number[];
  yearRound: boolean;
  notes: Bi;
  kidNote: Bi;
  funFact?: Bi;
  town: string;
  coords: [number, number];
  stories: Story[];
}

/** productId -> slot -> version */
export type ImageIndex = Record<string, Record<string, number>>;

export interface Explorer {
  id: string;
  name: string;
  avatar: string;
  completed: Record<string, string>;
  quizzes: Record<string, { best: number; total: number; at: string }>;
}

export interface Quiz {
  lang: Lang;
  questions: { question: string; options: string[]; answer: number; explanation: string }[];
}

export interface ChatMessage {
  role: 'user' | 'nonna';
  text: string;
}

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string,
    message: string,
  ) {
    super(message);
  }
}

async function request<T>(method: string, url: string, body?: unknown): Promise<T> {
  const res = await fetch(url, {
    method,
    headers: body === undefined ? undefined : { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
    credentials: 'same-origin',
  });
  if (res.status === 204) return undefined as T;
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new ApiError(res.status, data.error ?? 'error', data.message ?? res.statusText);
  return data as T;
}

export const api = {
  me: () => request<{ user: string; groups: string[]; ai: boolean }>('GET', '/api/me'),
  catalog: () => request<{ products: Product[]; images: ImageIndex }>('GET', '/api/catalog'),
  explorers: () => request<{ explorers: Explorer[] }>('GET', '/api/explorers'),
  addExplorer: (name: string, avatar: string) => request<{ explorer: Explorer }>('POST', '/api/explorers', { name, avatar }),
  removeExplorer: (id: string) => request<void>('DELETE', `/api/explorers/${id}`),
  setCompleted: (eid: string, pid: string, done: boolean) =>
    request<{ explorer: Explorer }>(done ? 'PUT' : 'DELETE', `/api/explorers/${eid}/completed/${pid}`),
  recordQuiz: (eid: string, pid: string, score: number, total: number) =>
    request<{ explorer: Explorer }>('POST', `/api/explorers/${eid}/quiz/${pid}`, { score, total }),
  generateImage: (pid: string, slot: string, redo = false) =>
    request<{ slot: string; version: number }>('POST', `/api/products/${pid}/images/${slot}`, { redo }),
  quiz: (pid: string, lang: Lang) => request<Quiz>('GET', `/api/products/${pid}/quiz?lang=${lang}`),
  chat: (pid: string, lang: Lang, messages: ChatMessage[]) =>
    request<{ reply: string }>('POST', `/api/products/${pid}/chat`, { lang, messages }),
};

export const imageUrl = (pid: string, slot: string, version: number) => `/media/${pid}/${slot}.webp?v=${version}`;
