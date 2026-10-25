import { createHash } from 'node:crypto';
import { promises as fs, existsSync, readdirSync, statSync, copyFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';

const hash = (value) => createHash('sha256').update(value).digest('hex').slice(0, 32);

async function writeAtomic(file, content) {
  await fs.mkdir(path.dirname(file), { recursive: true });
  const tmp = `${file}.${process.pid}.${Date.now()}.tmp`;
  await fs.writeFile(tmp, content);
  await fs.rename(tmp, file);
}

async function readJson(file, fallback) {
  try {
    return JSON.parse(await fs.readFile(file, 'utf8'));
  } catch (err) {
    if (err.code === 'ENOENT') return fallback;
    throw err;
  }
}

export const MAX_EXPLORERS = 8;
export const AVATARS = ['🦊', '🐰', '🦉', '🐢', '🐝', '🦔', '🐸', '🦋', '🐞', '🐿️'];

export function cleanExplorerName(name) {
  if (typeof name !== 'string') return null;
  const cleaned = name.normalize('NFC').replace(/[\p{C}<>]/gu, '').trim().slice(0, 24);
  return cleaned.length ? cleaned : null;
}

/** File-backed storage under DATA_DIR. One JSON file per portal user. */
export function createStore(dataDir) {
  const usersDir = path.join(dataDir, 'users');
  const imagesDir = path.join(dataDir, 'images');
  const quizDir = path.join(dataDir, 'quiz');
  const locks = new Map();

  function withLock(key, fn) {
    const prev = locks.get(key) ?? Promise.resolve();
    const next = prev.then(fn, fn);
    locks.set(key, next.catch(() => {}));
    return next;
  }

  const userFile = (user) => path.join(usersDir, `${hash(user)}.json`);
  const emptyUser = (user) => ({ user, explorers: [] });

  async function getUser(user) {
    return readJson(userFile(user), emptyUser(user));
  }

  function updateUser(user, mutate) {
    return withLock(`user:${user}`, async () => {
      const data = await getUser(user);
      const result = mutate(data);
      data.updatedAt = new Date().toISOString();
      await writeAtomic(userFile(user), JSON.stringify(data, null, 1));
      return result;
    });
  }

  function findExplorer(data, id) {
    return data.explorers.find((e) => e.id === id);
  }

  return {
    dataDir,
    async listExplorers(user) {
      return (await getUser(user)).explorers;
    },
    addExplorer(user, name, avatar) {
      return updateUser(user, (data) => {
        if (data.explorers.length >= MAX_EXPLORERS) return { error: 'too_many' };
        if (data.explorers.some((e) => e.name.toLowerCase() === name.toLowerCase())) return { error: 'exists' };
        const explorer = {
          id: hash(`${user}\n${name}\n${Date.now()}`).slice(0, 12),
          name,
          avatar: AVATARS.includes(avatar) ? avatar : AVATARS[data.explorers.length % AVATARS.length],
          completed: {},
          quizzes: {},
          createdAt: new Date().toISOString(),
        };
        data.explorers.push(explorer);
        return { explorer };
      });
    },
    removeExplorer(user, id) {
      return updateUser(user, (data) => {
        const before = data.explorers.length;
        data.explorers = data.explorers.filter((e) => e.id !== id);
        return before !== data.explorers.length;
      });
    },
    async getExplorer(user, id) {
      return findExplorer(await getUser(user), id) ?? null;
    },
    setCompleted(user, id, productId, done) {
      return updateUser(user, (data) => {
        const explorer = findExplorer(data, id);
        if (!explorer) return null;
        if (done) explorer.completed[productId] ??= new Date().toISOString();
        else delete explorer.completed[productId];
        return explorer;
      });
    },
    recordQuiz(user, id, productId, score, total) {
      return updateUser(user, (data) => {
        const explorer = findExplorer(data, id);
        if (!explorer) return null;
        const prev = explorer.quizzes[productId];
        if (!prev || score > prev.best) explorer.quizzes[productId] = { best: score, total, at: new Date().toISOString() };
        return explorer;
      });
    },

    imagesDir,
    imageFile: (productId, slot) => path.join(imagesDir, productId, `${slot}.webp`),
    async saveImage(productId, slot, buffer) {
      await writeAtomic(path.join(imagesDir, productId, `${slot}.webp`), buffer);
    },
    /** Map of productId -> { slot: version } for images present on disk. */
    scanImages() {
      const index = {};
      if (!existsSync(imagesDir)) return index;
      for (const productId of readdirSync(imagesDir)) {
        const dir = path.join(imagesDir, productId);
        if (!statSync(dir).isDirectory()) continue;
        for (const file of readdirSync(dir)) {
          if (!file.endsWith('.webp')) continue;
          (index[productId] ??= {})[file.slice(0, -5)] = Math.floor(statSync(path.join(dir, file)).mtimeMs);
        }
      }
      return index;
    },
    /** Copies bundled seed images into DATA_DIR without overwriting newer ones. */
    seedImages(seedDir) {
      if (!existsSync(seedDir)) return 0;
      let copied = 0;
      for (const productId of readdirSync(seedDir)) {
        const src = path.join(seedDir, productId);
        if (!statSync(src).isDirectory()) continue;
        for (const file of readdirSync(src)) {
          const target = path.join(imagesDir, productId, file);
          if (existsSync(target)) continue;
          mkdirSync(path.dirname(target), { recursive: true });
          copyFileSync(path.join(src, file), target);
          copied += 1;
        }
      }
      return copied;
    },

    getQuiz: (productId, lang) => readJson(path.join(quizDir, `${productId}.${lang}.json`), null),
    saveQuiz: (productId, lang, quiz) => writeAtomic(path.join(quizDir, `${productId}.${lang}.json`), JSON.stringify(quiz, null, 1)),
  };
}

/** In-memory daily quotas per portal user (reset at UTC midnight or restart). */
export function createQuota(limits) {
  let day = '';
  let used = new Map();
  return {
    take(user, kind) {
      const today = new Date().toISOString().slice(0, 10);
      if (today !== day) {
        day = today;
        used = new Map();
      }
      const key = `${kind}:${user}`;
      const count = used.get(key) ?? 0;
      if (count >= limits[kind]) return false;
      used.set(key, count + 1);
      return true;
    },
  };
}
