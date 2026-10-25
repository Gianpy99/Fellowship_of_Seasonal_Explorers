# AI Coding Agent Instructions - Fellowship of Seasonal Explorers

## What this is
A kids' (5–12) bilingual (Italian/English) web app about seasonal foods from Calabria and southern England,
published on the Family Portal (`C:\Development\FamilyPortal`) at `https://seasons.borrellofamily.co.uk/`.
Recurring characters: Lina (Calabrian girl), Taro (sprite from southern England), Nonna Rosa (grandmother), Piuma (robin).

## Architecture
- `web/` – Vite + Preact + TypeScript SPA, hash routes `#/`, `#/p/<id>`, `#/badges`. All UI text lives in
  `web/src/i18n.ts` (`it` and `en` must stay in sync). Season and badge logic plus speech are in `web/src/lib.ts`.
- `server/` – Node 22 + Express 5. `app.js` (routes, security headers, errors), `ai.js` (the **only** AI
  access: `createGeminiAi` and `createOpenAiAi` share one interface — `generateImage`, `generateJson`, `chat` —
  selected by `createAi` from `AI_PROVIDER`; failures become `AiError`), `prompts.js` (all prompts and JSON schemas), `store.js` (atomic JSON
  files and daily quotas), `config.js` (env).
- `content/` – read-only bundled data. `catalog.json` is **generated** by `scripts/build-catalog.mjs` from
  `content/source/seasonal_data.json` + optional `content/content-overrides.json`. Edit the source or overrides,
  then run `npm run catalog`; never hand-edit `catalog.json`.
- Runtime data lives in `DATA_DIR` (`/app/data` volume in production): `users/`, `images/<pid>/<slot>.webp`, `quiz/`.

## Rules
- Never send an AI key, or call an AI API, from the browser. Any new AI operation must be implemented for both
  providers in `ai.js`. Add new AI features as server routes that call
  `requireAi(req, 'imagesPerDay' | 'textPerDay')` (quota), and cache results on disk when they can be reused.
- Kid safety: keep the strict Gemini `safetySettings` and the OpenAI chat `moderation` block in `ai.js`, and keep prompts gentle, short and on-topic.
  Image prompts must say "no text".
- Auth is `portal` mode: trust `Remote-User`/`Remote-Groups` from Caddy; 401 in production without it.
  `/health` stays public. Explorer profiles are kid profiles inside one portal user.
- Keep the UI usable by kids: click targets ≥ 48px, emoji + words, every text in both languages.
- Legacy `seasonal_quest_app/` (Flutter) and `specs/` are reference only. Do not build on them.

## Commands
```powershell
npm run build; npm run dev        # http://localhost:8080 (DEV_USER=dev)
npm run typecheck; npm test       # run both before pushing (Jenkins runs them in the Docker test stage)
npm run catalog                   # rebuild content/catalog.json
npm run clean-content -- --dry-run
```

## Deployment
Every push to `main` deploys via `Jenkinsfile` on the Raspberry Pi (ARM64): Docker `test` stage → image →
container on `127.0.0.1:8096` → `/health` check → automatic rollback. The AI provider is `DEFAULT_AI_PROVIDER` in the
`Jenkinsfile`; its key comes from the Jenkins credential `seasonal-quest-<gemini|openai>-api-key`. Follow `FamilyPortal/docs/APP-ONBOARDING-GUIDE.md` for portal changes.
