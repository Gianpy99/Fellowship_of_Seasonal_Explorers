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
| Back-end | Node 22 + Express 5 (`server/`); the only place the AI key is used |
| AI | Google Gemini (`@google/genai`) or OpenAI (`openai`), chosen with `AI_PROVIDER` — an image model for illustrations, a fast text model for quizzes/chat |
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
| Secrets | Jenkins credential `seasonal-quest-gemini-api-key` or `seasonal-quest-openai-api-key` (see [AI keys](#ai-keys)) |
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
| `AI_PROVIDER` | auto | `gemini` or `openai`; empty = whichever key is set (Gemini first) |
| `GEMINI_API_KEY` | — | |
| `GEMINI_IMAGE_MODEL` | `gemini-nano-banana-2.1` | `gemini-3.1-flash-lite-image` is cheaper/faster |
| `GEMINI_TEXT_MODEL` | `gemini-3.1-flash-lite` | Quiz + chat |
| `GEMINI_CONTENT_MODEL` | `gemini-3.8-flash` | Only for `npm run clean-content` |
| `OPENAI_API_KEY` | — | |
| `OPENAI_IMAGE_MODEL` | `gpt-image-2.5-flare` | May require OpenAI organization verification |
| `OPENAI_IMAGE_QUALITY` | `medium` | `low` / `medium` / `high` |
| `OPENAI_TEXT_MODEL` | `gpt-6-luna` | Quiz + chat |
| `OPENAI_CONTENT_MODEL` | `gpt-6.1-sol` | Only for `npm run clean-content` |
| `AI_IMAGES_PER_DAY` / `AI_TEXT_PER_DAY` | `40` / `300` | Daily budget per portal user (HTTP 429 when reached) |

With no key at all the app still works; the AI buttons say that AI features are not enabled.

## AI keys

| Where | How |
| --- | --- |
| Local | `.env`: `GEMINI_API_KEY=...` and/or `OPENAI_API_KEY=...` (plus `AI_PROVIDER` if both are set) |
| Production key | Jenkins → *Manage Jenkins → Credentials → System → Global*: update (or add) the **Secret text** `seasonal-quest-gemini-api-key` / `seasonal-quest-openai-api-key`, then **Build Now**. Or on the Pi: `bash FamilyPortal/scripts/pi/seasonal-quest-jenkins-deploy.sh <key-file> <gemini\|openai>` |
| Production provider | `DEFAULT_AI_PROVIDER` at the top of the `Jenkinsfile` (commit + push). For a one-off test, use **Build with Parameters** → `AI_PROVIDER` |

The pipeline binds only the selected provider's credential and passes it to the container as
`GEMINI_API_KEY` or `OPENAI_API_KEY`. Keys never enter the image, the repo or the browser. If the
selected credential does not exist, the build stops before touching the running container.

## Development

```powershell
npm install
copy .env.example .env          # add GEMINI_API_KEY or OPENAI_API_KEY to try the AI features
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
- `npm run clean-content` is an optional one-off AI pass (about 56 calls, using the configured provider). It fixes Italian text sitting in English
  fields, grammar and gender agreement, and adds a fun fact and emoji per product. It writes
  `content/content-overrides.json` and rebuilds the catalog. Re-running it skips products already done
  (`--force` redoes them, `--only=id1,id2` limits them, `--dry-run` only counts). Review the diff before committing.

### AI safety and cost

- The key never reaches the browser; all AI calls go through `/api`. Gemini calls use the strictest safety
  thresholds; with OpenAI, images use the default (`auto`) moderation and the chat blocks flagged input/output.
  Nonna Rosa's system prompt keeps her on-topic, short and kind.
- Images are generated only when a child presses **✨ Paint**. Each one is stored as WebP, served with a
  1-year immutable cache and reused for everyone. Parallel requests for the same picture are merged.
- Quizzes are generated once per product and language, then cached on disk.
