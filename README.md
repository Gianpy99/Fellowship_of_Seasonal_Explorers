# 🍋 Fellowship of Seasonal Explorers

A family web app where kids (5–12) discover seasonal fruit, vegetables, flowers and farm foods
from **Calabria** and **southern England**, together with Lina, Taro the sprite, Nonna Rosa and Piuma the robin.

- 🗓️ Month-by-month "what's in season", category and region filters, cards or an OpenStreetMap map
- 📖 Three kinds of bilingual stories (🇮🇹/🇬🇧) per product, with 🔊 read-aloud (browser speech, free and offline)
- 🎨 **AI illustrations on demand** (Google Gemini image model), generated once and cached for everyone
- 🧠 AI quizzes per product (generated once per language, then cached)
- 👵 **Ask Nonna Rosa**: a kid-safe, on-topic chat
- ⭐ Explorer profiles per child, "I discovered it!" progress, 12 badges, Street View / Google Maps links

Published on the Family Portal at **https://seasons.borrellofamily.co.uk/**.

## Architecture

| Part | Tech |
| --- | --- |
| Front-end | Vite + Preact + TypeScript (`web/`), ~60 KB gzipped, Leaflet + OpenStreetMap |
| Back-end | Node 22 + Express 5 (`server/`); the only place the Gemini key is used |
| AI | `@google/genai` — image model for illustrations, a fast text model for quizzes/chat |
| Content | `content/catalog.json`, built from `content/source/seasonal_data.json` |
| Storage | Files under `DATA_DIR`: explorers per portal user, generated WebP images, cached quizzes |

```
content/   bundled, read-only content (catalog, raw source, seed images)
scripts/   build-catalog.mjs (raw -> catalog), clean-content.mjs (one-off AI text clean-up)
server/    Express API, Gemini wrapper, prompts, file store, tests
web/       Preact front-end (built into dist/)
```

The old Flutter prototype (`seasonal_quest_app/`) and the planning docs (`specs/`) are kept for reference only.
They are not built or deployed and can be removed.

## Family Portal contract

| Item | Value |
| --- | --- |
| App id | `seasonal-quest` |
| Public URL | `https://seasons.borrellofamily.co.uk/` |
| Host port | `127.0.0.1:8096` → container `8080` |
| Health | `GET /health` (no login) → `{"status":"ok"}` |
| Auth mode | `portal`: Caddy does the login; the app trusts `Remote-User` / `Remote-Groups` and returns 401 without them in production |
| Data volume | `seasonal-quest-data` → `/app/data` |
| Secrets | Jenkins credential `seasonal-quest-gemini-api-key` → `GEMINI_API_KEY` |
| Deploy | `Jenkinsfile`: Docker `test` stage → build → run → health check → rollback |

Because the portal currently shares one login per family, each child gets an **explorer profile**
(name + animal avatar) inside the portal user, with separate progress.

## Environment variables

| Name | Default | Notes |
| --- | --- | --- |
| `APP_ENV` | `development` | `production` requires the `Remote-User` header |
| `PORT` | `8080` | |
| `DATA_DIR` | `./.data` | `/app/data` in the container |
| `DEV_USER` | `dev` | Local user when not in production |
| `GEMINI_API_KEY` | — | Empty = app works, AI features hidden |
| `GEMINI_IMAGE_MODEL` | `gemini-nano-banana-2.1` | `gemini-3.1-flash-lite-image` is cheaper/faster |
| `GEMINI_TEXT_MODEL` | `gemini-3.1-flash-lite` | Quiz + chat |
| `GEMINI_CONTENT_MODEL` | `gemini-3.8-flash` | Only for `npm run clean-content` |
| `AI_IMAGES_PER_DAY` / `AI_TEXT_PER_DAY` | `40` / `300` | Daily budget per portal user (HTTP 429 when reached) |

## Development

```powershell
npm install
copy .env.example .env          # add GEMINI_API_KEY to try the AI features
npm run build                   # build the front-end into dist/
npm run dev                     # API + built front-end on http://localhost:8080
npm run dev:web                 # optional: Vite hot reload on http://localhost:5173 (proxies /api)

npm run typecheck
npm test                        # server tests (fake AI, no API calls)
docker compose up --build       # production image on http://localhost:8096
```

### Content

- `npm run catalog` rebuilds `content/catalog.json` from the raw source and
  `content/content-overrides.json` (if present).
- `npm run clean-content` is an optional one-off Gemini pass (about 56 calls). It fixes Italian text sitting in English
  fields, grammar and gender agreement, and adds a fun fact and emoji per product. It writes
  `content/content-overrides.json` and rebuilds the catalog. Re-running it skips products already done
  (`--force` redoes them, `--only=id1,id2` limits them, `--dry-run` only counts). Review the diff before committing.

### AI safety and cost

- The key never reaches the browser; all AI calls go through `/api`. Every Gemini call uses the strictest safety
  thresholds. Nonna Rosa's system prompt keeps her on-topic, short and kind.
- Images are generated only when a child presses **✨ Paint**. Each one is stored as WebP, served with a
  1-year immutable cache and reused for everyone. Parallel requests for the same picture are merged.
- Quizzes are generated once per product and language, then cached on disk.
