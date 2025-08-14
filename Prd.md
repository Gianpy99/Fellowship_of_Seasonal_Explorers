# Product Requirements Document (PRD)
**Project Name:** Fellowship of Seasonal Explorer  
**Owner:** Solo build (you)  
**Date:** 2025-08-14  

---

## 1) Problem Statement
People want playful, meaningful reasons to get outside and explore their surroundings through the changing seasons, but most apps are either generic step counters or static lists of attractions. There’s no lightweight, family-friendly experience that blends seasonal challenges, geolocation quests, and photo/story prompts into a cohesive, safe, and motivating journey.

---

## 2) Goals & Objectives
- **Inspire seasonal exploration** with rotating quests tailored to weather, holidays, and local nature/culture.
- **Encourage mindful discovery** via photo prompts, journaling snippets, and small “acts of wonder.”
- **Make it lightweight & safe** for solo or family use, with privacy-first location handling.
- **Reward continuity** through streaks, badges, and seasonal “fellowship” rankings.

---

## 3) Target Users
- **Primary:** Individuals and families seeking low-pressure outdoor prompts and micro-adventures.
- **Secondary:** Educators or community leaders who want seasonal scavenger hunts/events.
- **Tertiary:** Travelers looking for hyperlocal, time-bound experiences.

---

## 4) Core Features

### MVP
1. **Seasonal Quest Packs** (Spring/Summer/Autumn/Winter) with 10–20 quests each.  
2. **Geolocated Check-ins** (radius-based, no continuous tracking; opt-in GPS).  
3. **Photo Prompts & Micro-Journals** attached to completed quests.  
4. **Progress & Badges** (per-season progress bar, basic badges).  
5. **Offline-first Mode** (queue check-ins, sync later).  
6. **Privacy Controls** (local-first data, no sharing by default).

### Phase 2
7. **Dynamic Weather Hooks** (unlock or boost certain quests based on current conditions).  
8. **Team “Fellowships”** (private groups for family/friends; shared board of completed quests).  
9. **Event Quests** (limited-time holidays/festivals).

### Phase 3
10. **Creator Tools** for custom quest packs (shareable via code or link).  
11. **Local Integrations** (parks, museums) to surface sponsored/community quests.  
12. **AR Hints** (optional) for wayfinding or overlays.

---

## 5) Non-Functional Requirements
- **Privacy:** Location data stored locally; explicit opt-in for any sharing.  
- **Performance:** App start < 2s; check-in flow < 5s on mid-range phone.  
- **Reliability:** Offline queues resilient to app restarts; zero data loss.  
- **Portability:** iOS, Android (cross-platform) with a minimal web dashboard.

---

## 6) Constraints
- Solo development → keep scope lean; favor content tooling over complex 3D/AR initially.  
- Geolocation accuracy varies; design quests tolerant to GPS drift (50–150m).  
- Seasonal content cadence requires lightweight authoring pipeline.

---

## 7) Tech Stack Suggestion
- **App:** React Native (Expo) or Flutter for cross-platform.  
- **Local Storage:** SQLite (expo-sqlite) or Hive (Flutter).  
- **Sync Backend (optional):** Supabase or Firebase (auth, storage, lightweight functions).  
- **Maps/Geo:** MapLibre or Google Maps SDK; geofencing via OS APIs where available.  
- **Media:** On-device compression before upload; EXIF scrub on share.

---

## 8) Success Metrics
- **Activation:** 70% of new users complete 3 quests in first 7 days.  
- **Retention:** 35% D30 retention for users who complete ≥5 quests.  
- **Creation:** 20% of active users post at least one photo/journal entry per week.  
- **Privacy Trust:** < 1% opt-out due to privacy concerns (measured via settings flag).

---

## 9) Roadmap

| Phase     | Duration  | Key Deliverables |
|-----------|-----------|------------------|
| **MVP**   | 4–6 weeks | 4 seasonal packs, geo check-in, photo/journal, badges, offline-first |
| **Phase 2** | +4 weeks | Weather hooks, private fellowships, event quests |
| **Phase 3** | +6 weeks | Creator tools, local org integrations, optional AR hints |

---

## 10) Risks & Mitigation
- **GPS Inaccuracy / Urban Canyons** → Use radius buffers, allow manual verify with photo prompt.  
- **Content Burnout** → Build a YAML/JSON quest authoring pipeline; rotate packs seasonally.  
- **Privacy Sensitivity** → Default-local data, no background tracking, simple exports, anonymous mode.  
- **Scope Creep** → AR and complex social stay in Phase 3; enforce MVP guardrails.

---

## 11) Open Questions
- Should quests scale by **difficulty/time** (5/15/30-minute tiers) in MVP or Phase 2?  
- Do we need **language-localized** quest content from day one?  
- Should photo journals support **private-to-group sharing** in MVP or wait for fellowships?

---
