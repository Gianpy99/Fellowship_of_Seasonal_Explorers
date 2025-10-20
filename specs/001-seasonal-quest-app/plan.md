# Implementation Plan: Seasonal Quest App for Family Education

**Branch**: `001-seasonal-quest-app` | **Date**: 2025-10-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-seasonal-quest-app/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Educational mobile app for families with children ages 5-12 to explore seasonal foods and nature through location-based quests. Core functionality includes browsing seasonal quests, GPS-based check-ins with photo capture, educational content display, progress tracking with badges, and AI-powered recommendations. Technical approach prioritizes offline-first architecture with local storage, child-friendly UI with large touch targets and simple navigation, and privacy-by-default design with no background tracking.

## Technical Context

**Platform**: Flutter Web 3.16+ (web-first deployment for desktop/laptop browsers)  
**Language/Version**: Dart 3.2+ (compiled to JavaScript/WASM for web)  
**Primary Dependencies**: 
- `flutter_web_plugins` (Flutter's web plugin system)
- `google_maps_flutter_web` (Google Maps JavaScript API wrapper)
- `flutter_riverpod` (simple state management)
- `shared_preferences` / `shared_preferences_web` (browser LocalStorage wrapper)
- `image_picker_for_web` (webcam capture via MediaDevices API)
- `geolocator` / `geolocator_web` (browser Geolocation API - optional)
- `google_generative_ai` (Gemini AI SDK - optional, parental opt-in only)

**Storage**: Browser LocalStorage (JSON text for settings/progress) + IndexedDB (binary Blob for photos) - fully offline PWA  
**Maps**: Google Maps JavaScript API + Street View (primary quest exploration method)  
**Testing**: Flutter web testing framework (`flutter test`) with widget tests for UI, unit tests for logic  
**Target Platform**: Modern browsers (Chrome 90+, Firefox 88+, Safari 14+, Edge 90+) on desktop/laptop (1366x768 primary resolution)  
**Project Type**: Progressive Web App (PWA) with Service Workers for offline capability  
**Performance Goals**: 
- App startup <3 seconds on broadband (10 Mbps+)
- Google Maps load <5 seconds
- Street View load <3 seconds per panorama
- Quest list rendering <2 seconds
- Webcam photo capture and save <1 second
- Smooth 60fps animations (CanvasKit renderer)

**Key Constraints**:
- Offline-capable architecture (core features work without internet, using browser storage)
- Privacy-first (local browser storage, no tracking, no accounts)
- Child-safe UX (large click targets 48x48px, gentle colors, no timers/stress, keyboard accessible WCAG 2.1 Level AA)
- Family use only (not production scale - simple is better than robust)
- Extreme simplicity (JSON in LocalStorage, straightforward patterns)
- Desktop/laptop focus (kids use family computer, not personal devices yet)
- Virtual exploration primary (Google Maps Street View main quest completion method since desktop GPS unreliable)

**Scale/Scope**: 
- Single family use (1-5 users sharing browser)
- ~80 quests across 4 seasons and 2 regions (Calabria, South England)
- ~100 screens/widgets total
- Expected usage: 2-5 sessions per week, 10-20 minutes per session
- Browser storage: ~200KB JSON + ~50MB photos (250 quests max)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Note**: No constitution file exists yet for this project. This is the first feature specification and implementation plan. For future features, a constitution should be created to establish consistent architectural principles, testing requirements, and development standards.

**Recommended Constitution Principles** (to be formalized):
1. **Privacy-First**: All features must default to local storage; any cloud sync requires explicit user opt-in
2. **Child-Safe Design**: UI must follow COPPA guidelines; no data collection, no ads, no external links without parental controls
3. **Offline-First**: Core functionality must work without internet connectivity
4. **Test Coverage**: Critical user flows (quest completion, photo capture, badge earning) require widget/integration tests
5. **Simplicity**: Prefer simple solutions over complex abstractions; YAGNI principles apply

**Current Status**: ✅ PASS - No gates to violate as constitution doesn't exist yet

## Project Structure

### Documentation (this feature)

```
specs/001-seasonal-quest-app/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output - Technology decisions and patterns
├── data-model.md        # Phase 1 output - Entity schemas and relationships
├── quickstart.md        # Phase 1 output - Developer setup guide
├── contracts/           # Phase 1 output - API contracts (minimal, mostly local)
│   └── gemini-ai.md     # Gemini AI integration contract
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created yet)
```

### Source Code (repository root)

```
seasonal_quest_web/              # Flutter Web application (PWA)
├── lib/
│   ├── main.dart                        # App entry point
│   ├── models/                          # Data models
│   │   ├── quest.dart
│   │   ├── quest_location.dart          # lat/lng + Street View panorama ID
│   │   ├── quest_completion.dart
│   │   ├── virtual_exploration_session.dart  # NEW: Street View tracking
│   │   ├── badge.dart
│   │   ├── journal_entry.dart
│   │   ├── user_progress.dart
│   │   └── story_character.dart
│   ├── services/                        # Business logic layer
│   │   ├── quest_service.dart           # Quest management
│   │   ├── google_maps_service.dart     # NEW: Google Maps + Street View wrapper
│   │   ├── geolocation_service.dart     # Browser Geolocation API (optional)
│   │   ├── storage_service.dart         # LocalStorage/IndexedDB wrapper
│   │   ├── webcam_service.dart          # NEW: MediaDevices API (webcam capture)
│   │   ├── ai_service.dart              # Gemini integration (parental opt-in)
│   │   ├── badge_service.dart           # Achievement logic
│   │   └── export_service.dart          # PDF/album generation
│   ├── screens/                         # UI screens (desktop optimized, keyboard nav)
│   │   ├── home_screen.dart             # Google Map with 80 quest markers
│   │   ├── quest_detail_screen.dart     # Quest info + Street View embed
│   │   ├── street_view_screen.dart      # NEW: Full-screen Street View exploration
│   │   ├── completion_screen.dart       # Success celebration with badge
│   │   ├── journal_screen.dart          # Photo journal entries
│   │   ├── progress_screen.dart         # Dashboard with badges & stats
│   │   └── settings_screen.dart         # Parent controls & privacy
│   ├── widgets/                         # Reusable UI components
│   │   ├── quest_card.dart              # Large, colorful quest preview (48x48px click target)
│   │   ├── quest_marker.dart            # NEW: Custom map marker (product icons)
│   │   ├── street_view_widget.dart      # NEW: Embeddable Street View panorama
│   │   ├── badge_widget.dart            # Animated badge display
│   │   ├── character_avatar.dart        # Story character icons
│   │   ├── progress_ring.dart           # Visual progress indicator
│   │   └── keyboard_button.dart         # NEW: Keyboard-accessible button (focus indicators)
│   ├── providers/                       # Riverpod state management
│   │   ├── quest_provider.dart
│   │   ├── maps_provider.dart           # NEW: Google Maps state
│   │   ├── progress_provider.dart
│   │   └── settings_provider.dart
│   ├── utils/                           # Helper utilities
│   │   ├── constants.dart               # Colors, sizes, spacing (48x48px min click target)
│   │   ├── keyboard_shortcuts.dart      # NEW: Tab/Enter/Escape handlers
│   │   ├── validators.dart              # Input validation
│   │   └── date_helpers.dart            # Season detection
│   └── data/                            # Static content
│       ├── quests_calabria.json         # Regional quest packs with lat/lng
│       ├── quests_england.json
│       └── story_characters.json        # Lina, Taro, Nonna Rosa, Piuma
├── web/                                 # Web-specific files
│   ├── index.html                       # Google Maps API key injection
│   ├── manifest.json                    # PWA configuration
│   ├── favicon.png
│   ├── icons/                           # PWA icons (192x192, 512x512)
│   └── assets/                          # Bundled at build time
│       ├── images/                      # Pre-generated from Python pipeline
│       │   ├── icons/
│       │   ├── story_scenes/
│       │   └── recipes/
│       ├── badges/                      # Achievement badge graphics
│       ├── characters/                  # Story character illustrations
│       └── data/                        # Quest JSON files
├── test/
│   ├── widget_test/                     # UI component tests
│   ├── unit_test/                       # Service & model tests
│   └── browser_test/                    # NEW: Browser API integration tests
├── pubspec.yaml                         # Dependencies
└── README.md                            # Setup instructions
```

**Structure Decision**: Flutter Web PWA chosen because:
1. **Family Computer Context**: Kids ages 5-12 use supervised family desktop/laptop (not allowed personal mobile devices yet)
2. **Virtual Exploration**: Google Maps Street View enables "walking" through quest locations worldwide without travel
3. **90% Code Reuse**: When kids allowed mobile devices (Phase 8), same Dart codebase builds iOS/Android apps
4. **Instant Deployment**: No app stores, URL sharing, automatic updates on page reload
5. **Browser APIs**: Direct access to Geolocation, MediaDevices (webcam), LocalStorage for offline PWA
6. **Keyboard Navigation**: Desktop UX requires full keyboard accessibility (WCAG 2.1 Level AA) with Tab/Enter/Escape

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

**Status**: N/A - No constitution exists yet, therefore no violations to track.

