# AI Coding Agent Instructions - Fellowship of Seasonal Explorers

## Project Overview
This project generates AI-powered illustrated content for a seasonal food education database aimed at families and children. It combines a structured JSON database of seasonal products (fruits, vegetables, flowers, animal products) with AI-generated imagery in Ghibli/Disney/Tolkien fantasy style.

**Two parallel product visions exist:**
1. **Current implementation**: Image generation pipeline for educational seasonal food database with whimsical stories
2. **Future vision** (see `Prd.md`, `Prd2.md`): Geolocation-based seasonal exploration app with quests, gamification, and social features

Focus on the **current implementation** (image generation) unless explicitly directed to the future app concept.

## Core Architecture

### Data Model
The canonical data source is `seasonal_db_complete_story_cards__WITH_3x_stories_20250813_101620.json` (7227 lines):
- **Structure**: `{"products": [...]}`  
- **Product schema**: `id`, `it`/`en` (names), `category`, `harvest_months`, `shelf_months`, `icon`, `notes_it`/`notes_en`, `educational_text`, `stories` (Calabria/Bassa Inghilterra with `it`/`en` arrays)
- **Recurring story characters**: Lina (curious Calabrian girl), Taro (traveling elf from South England), Nonna Rosa (wise tradition-keeper), Piuma (talking robin)

### Image Generation Pipeline
Three Python scripts generate different image types using **Stable Diffusion (Ghibli-Diffusion model)**:

1. **`ImageGenerator.py`**: Basic story scene generator  
   - Single-threaded, processes all products sequentially
   - Generates 1 scene per story using the Italian story text as prompt basis

2. **`generate_sample_bergamotto.py`**: Proof-of-concept single-product tester  
   - Tests generation for "Bergamotto" product only
   - Useful for validating prompts before full batch runs

3. **`generate_all_with_estimation_seed_quality_parallel.py`**: Production pipeline ⭐
   - **Most sophisticated script** - use this as the reference implementation
   - Generates 3 image types: icons (512x512), story scenes (768x768), recipes (640x640)
   - **Quality control**: Automatic sharpness detection with regeneration on low quality
   - **Parallel I/O**: ThreadPoolExecutor for save/quality-check while GPU generates next image
   - **Resumable**: `--resume` flag + `images_mapping.json` state tracking
   - **Deterministic seeds**: Hash-based per product for reproducibility
   - **CLI options**: `<num_variations>`, `<product_filter>`, `--resume`, `--preview`, `--min-sharpness=X`

### Key Technical Patterns

#### GPU Resource Management
- **Model**: `nitrosocke/Ghibli-Diffusion` (requires 6GB VRAM minimum, targets GTX 1660)
- **Precision**: `torch.float16` for memory efficiency
- **Pipeline reuse**: Single pipe instance across all generations to avoid reload overhead

#### Prompt Engineering
Three distinct style presets hardcoded as constants:
```python
ICON_STYLE = "charming illustration, Studio Ghibli style, simple background, centered subject..."
SCENE_STYLE = "beautiful whimsical illustration, Studio Ghibli style, Disney magic, Tolkien fantasy..."
RECIPE_STYLE = "beautiful cooking illustration, Studio Ghibli style, storybook recipe art..."
```
Prompts combine: `{STYLE} + {variation} + scene depicting: {story_text} + main focus on {product_name}`

#### Quality Assurance
- `calculate_sharpness()`: Edge-detection filter (PIL `ImageFilter.FIND_EDGES`) 
- Default threshold: 10.0 (adjustable via `--min-sharpness=X`)
- Automatic regeneration (max 2 attempts) on quality failure

#### Output Organization
```
images_icons/           # Product icons (centered, minimal background)
images_story_scenes_random/  # Narrative scenes with random variations
images_recipes/         # Recipe illustrations
images_mapping.json     # State file: {product_name: {icon, stories[], recipes[]}}
```

## Developer Workflows

### Repository Setup
```powershell
# Repository initialized with:
git init --here
# This creates the repository in the current directory without a subdirectory
```

### Running Image Generation
```powershell
# Preview estimation without generating
python generate_all_with_estimation_seed_quality_parallel.py --preview

# Full generation with 2 story variations per scene
python generate_all_with_estimation_seed_quality_parallel.py 2

# Resume interrupted generation
python generate_all_with_estimation_seed_quality_parallel.py --resume

# Generate for specific product only
python generate_all_with_estimation_seed_quality_parallel.py bergamotto

# Custom quality threshold (higher = stricter)
python generate_all_with_estimation_seed_quality_parallel.py --min-sharpness=12.0 2
```

### Testing Single Product
```powershell
# Quick validation before batch processing
python generate_sample_bergamotto.py
```

### Hardware Requirements
- **VRAM**: 6GB minimum (GTX 1660 tested)
- **RAM**: 8GB recommended
- **Storage**: ~1.5MB per image (estimate function: `AVG_IMG_SIZE_MB`)
- **Time**: ~10 sec/image (estimate: `AVG_GEN_TIME`)

## Project-Specific Conventions

### Naming Conventions
- **Files**: `{product_name_en_lowercase_underscored}_{type}{index}_{variation}.png`  
  Example: `bergamot_story1_sunset_lighting.png`
- **Product IDs**: `{name_en_lowercase}_calabria` pattern in JSON
- **Constants**: ALL_CAPS for configuration (MODEL_ID, GUIDANCE_SCALE, etc.)

### Story Variations System
Hardcoded variation descriptors in `VARIATIONS` list:
```python
["sunset lighting", "early morning mist", "sparkles of magic in the air", 
 "colorful market background", "forest clearing with flowers", ...]
```
Randomly selected and appended to scene prompts for visual diversity.

### Bilingual Design
All content maintains parallel Italian/English (`it`/`en`) structure:
- UI-facing content in JSON uses `it`/`en` keys
- Story prompts use Italian text (`stories_it`) but generate universally-styled images

### State Management
- `images_mapping.json`: Tracks generated files per product
- Resume mode checks file existence: `Path(filename).exists()`
- No database - filesystem is the source of truth for generation status

## Critical Dependencies
```python
diffusers          # Stable Diffusion pipeline
torch              # GPU acceleration (CUDA required)
Pillow (PIL)       # Image quality analysis
```

## Common Pitfalls
1. **Don't modify story text directly in scripts** - edit `seasonal_db_complete_story_cards__WITH_3x_stories_20250813_101620.json`
2. **GPU memory errors**: Reduce `NUM_INFERENCE_STEPS` or `IMAGE_SIZE` before increasing batch size
3. **Quality threshold too high**: Default 10.0 works for Ghibli style; >15.0 may cause infinite regeneration
4. **Missing CUDA**: Scripts fail without NVIDIA GPU - no CPU fallback implemented

## Integration Points
- **Input**: JSON database (seasonal products with stories/recipes)
- **Output**: PNG files organized by type + `images_mapping.json` manifest
- **Future integration**: Generated images intended for mobile app UI (see PRDs) but no app implementation exists yet

## When Extending This Codebase
- **Adding new image types**: Follow the icon/scene/recipe pattern in the main script
- **New style presets**: Define as module-level constants (see `ICON_STYLE`, `SCENE_STYLE`)
- **Product filtering**: Use `product_filter` CLI arg (matches `name_it` or `name_en` substring)
- **Performance tuning**: Adjust `ThreadPoolExecutor(max_workers=2)` cautiously - GPU is bottleneck, not I/O

---

## New Feature: Seasonal Quest Web App (In Planning)

**Status**: Specification and planning phase complete (see `specs/001-seasonal-quest-app/`)  
**Platform Priority**: **Web-first** (desktop/laptop browsers), mobile/tablet apps later  
**Tech Stack**: ✅ **Flutter Web 3.16+** with Dart 3.2+ (DECIDED)  
**Storage**: Browser LocalStorage + IndexedDB (JSON-based) - fully offline-capable  
**Key Feature**: 🗺️ **Google Maps Street View Integration** for virtual quest exploration  
**Purpose**: Educational web app for families with children ages 5-12 to explore seasonal foods and nature

### Key Context for Web-First Development
1. **User Environment**: Kids ages 5-12 use family desktop/laptop computer (not allowed personal mobile/tablet devices yet)
2. **Interaction**: Mouse + keyboard navigation (not touch), large click targets (48x48px minimum)
3. **Camera**: Webcam via MediaDevices API (not mobile rear camera) - delayed photo capture workflow
4. **GPS**: Browser Geolocation API (unreliable on desktop) - **Google Maps Street View becomes primary exploration method**
5. **Offline**: Service Workers + LocalStorage for core features (no native file system)
6. **Virtual Exploration**: Kids can "walk" in Google Maps Street View to explore quest locations worldwide (educational geography!)

### Architecture & Technology
- **Framework**: Flutter Web (90% code reuse for future mobile apps)
- **Maps**: `google_maps_flutter_web` - embed Google Maps with custom quest markers
- **Street View**: JavaScript API integration - virtual exploration of farmers markets, orchards, etc.
- **Storage**: `shared_preferences` for settings, LocalStorage for quest data and photos
- **Camera**: `image_picker_for_web` for webcam capture (requires HTTPS)
- **AI**: `google_generative_ai` for Gemini recommendations (optional, parental opt-in)

### Quest Completion Flow
1. Browse seasonal quests on map (satellite view with custom fruit/vegetable markers)
2. Click quest → Opens Street View at location (e.g., Reggio Calabria market for Bergamotto)
3. "Explore" location using Street View navigation (arrow keys, mouse drag)
4. Find landmarks/markers related to seasonal product
5. Complete quest by capturing webcam photo at home OR marking as "explored virtually"
6. Earn badges for exploration milestones

### Architecture Pivot Summary
- **Before**: Flutter mobile app → iOS/Android native apps
- **After**: ✅ Flutter Web first → Desktop/laptop browsers → Mobile apps later (Phase 8)
- **Reason**: Family computer context, kids not allowed personal devices, educational geography focus
- **Benefit**: Kids can explore Calabrian markets or English orchards from home computer
- **See**: `specs/001-seasonal-quest-app/WEB_FIRST_CHANGES.md` and `PHASE0_PROTOTYPES.md`

### Documentation
- **Specification**: `specs/001-seasonal-quest-app/spec.md`
- **Implementation Plan**: `specs/001-seasonal-quest-app/plan.md`
- **Data Model**: `specs/001-seasonal-quest-app/data-model.md`
- **Developer Guide**: `specs/001-seasonal-quest-app/quickstart.md`
- **API Contracts**: `specs/001-seasonal-quest-app/contracts/gemini-ai.md`

### Migration Strategy
Transform existing `seasonal_db_complete_story_cards__WITH_3x_stories_20250813_101620.json` into Flutter-compatible quest data, bundle pre-generated images in app assets, and build offline-first mobile experience prioritizing child safety and educational value.
