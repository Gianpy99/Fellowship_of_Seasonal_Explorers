# Research: Seasonal Quest Web App Technical Decisions

**Date**: 2025-10-20  
**Feature**: Seasonal Quest Web App for Family Education  
**Purpose**: Document technology choices, patterns, and best practices for child-safe, offline-capable educational **web application** with Google Maps Street View integration

## Key Technical Decisions

### 1. Platform & Framework: ✅ Flutter Web (DECIDED)

**Decision**: Use Flutter Web 3.16+ with Dart 3.2+ for web-first deployment

**Rationale**:
- **90% Code Reuse for Future Mobile**: When kids are allowed mobile/tablet devices (Phase 8), can build iOS/Android apps from same Dart codebase
- **Single Language**: Dart for frontend + backend logic eliminates context switching
- **Google Maps Integration**: `google_maps_flutter_web` package provides seamless Google Maps JavaScript API wrapper with custom markers and Street View support
- **Offline PWA Support**: Service Workers for caching quests, images, and educational content
- **Child-Friendly UI**: Flutter's widget library creates large click targets, smooth animations, and accessible keyboard navigation
- **Family Computer Context**: Optimized for desktop/laptop (1366x768 primary viewport) where kids use supervised family computer
- **Browser APIs**: Direct access to Geolocation API, MediaDevices API (webcam), LocalStorage/IndexedDB for data persistence
- **Educational Geography**: Street View enables virtual exploration of Calabrian markets, English orchards without travel

**Platform Context**:
- **Primary**: Desktop browsers (Chrome, Firefox, Safari) on family computer
- **Input**: Keyboard + Mouse (not touch) with full keyboard navigation (Tab, Enter, Escape, Arrow keys)
- **Target Users**: Children ages 5-12 using supervised family computer (not personal mobile devices)

**Alternatives Considered**:
- **React + Next.js**: 
  - **Pros**: Better web ecosystem, easier deployment (Vercel), more web developer resources
  - **Cons**: No code reuse for future mobile apps, need TypeScript + React context switches
  - **Verdict**: Rejected - Flutter Web's mobile reusability outweighs React's web maturity
  
- **Native Mobile Apps (Flutter iOS/Android)**: 
  - **Pros**: Better camera quality, accurate GPS, touch-optimized
  - **Cons**: Kids don't have personal devices yet, app store friction, slower deployment
  - **Verdict**: Deferred to Phase 8 when kids allowed devices

- **PWA-Only (Vanilla JS)**: 
  - **Pros**: Lightweight, no framework overhead
  - **Cons**: Reinventing UI components, poor state management, no mobile future
  - **Verdict**: Rejected - not sustainable for growing feature set

**Flutter Web Performance Considerations**:
- Initial load: ~2-3 MB (canvaskit renderer), acceptable on broadband
- Lazy loading: Split code to load quest packs on-demand
- Caching: Service Worker caches compiled WASM for repeat visits

**Technical Stack Summary**:
```yaml
Platform: Web (desktop/laptop browsers)
Framework: Flutter Web 3.16+
Language: Dart 3.2+
Rendering: CanvasKit (default) for consistent cross-browser rendering
Maps: Google Maps JavaScript API via google_maps_flutter_web
Storage: Browser LocalStorage (settings) + IndexedDB (photos, quest data)
Camera: MediaDevices API (getUserMedia) via image_picker_for_web
GPS: Browser Geolocation API (optional, degraded on desktop)
Offline: Service Workers + Cache API for PWA functionality
```

### 2. State Management: Riverpod

**Decision**: Use `flutter_riverpod` for state management

**Rationale**:
- **Simplicity**: Cleaner than Provider, easier to understand for straightforward app logic
- **Compile-Time Safety**: Catches errors during development, not at runtime
- **Testing-Friendly**: Easy to mock providers for widget tests
- **Lightweight**: No boilerplate, perfect for family-scale app
- **Offline-Friendly**: Works seamlessly with local data sources

**Alternatives Considered**:
- **BLoC**: Rejected as overly complex for this scope; overkill for simple state needs
- **GetX**: Rejected due to magic/global state concerns; Riverpod more explicit
- **setState only**: Rejected as insufficient for cross-screen state (progress, badges)

### 3. Local Storage: JSON Files + File System

**Decision**: Use JSON files for structured data + `path_provider` for photos

**Rationale**:
- **Extreme Simplicity**: Read/write JSON with `dart:convert` - no database library needed
- **Human-Readable**: Can inspect and edit files directly for debugging
- **No Migration Complexity**: JSON schema changes are simple file updates
- **Proven Pattern**: Flutter apps commonly use JSON for small-to-medium datasets
- **Privacy-First**: All data local by default; JSON files in app-scoped directory
- **Photo Storage**: File system for images (compressed JPEGs) with paths stored in JSON
- **Export Support**: JSON already in portable format; easy to generate PDF from data
- **Family Scale**: <100 quests, <200 completions fits comfortably in JSON

**Storage Structure**:
```
app_data/
├── data/
│   ├── user_progress.json       # Single file: completed quests, badges, streaks
│   ├── journal_entries.json     # Photo journals with metadata
│   ├── ai_recommendations.json  # Cached AI suggestions (optional)
│   └── settings.json            # App preferences
├── photos/
│   ├── {uuid-1}.jpg             # Compressed quest photos
│   └── {uuid-2}.jpg
└── exports/
    └── journal_2025-10-20.pdf   # Exported albums
```

**Alternatives Considered**:
- **SQLite (sqflite)**: Rejected as overkill for family-scale data; adds complexity without benefit
- **Hive**: Rejected; JSON simpler and more transparent for debugging
- **Cloud-First (Firebase)**: Rejected - violates privacy-first requirement; no cloud needed at all
- **Shared Preferences**: Too limited for structured data; JSON files more flexible

**Migration Path** (if needed later):
- If data grows beyond comfort (~1000 completions), can migrate JSON → SQLite
- But for family use, JSON will be sufficient indefinitely

### 4. AI Integration: Gemini API (Free Tier)

**Decision**: Use Google Generative AI SDK with Gemini 1.5 Flash model

**Rationale**:
- **User Specified**: Gemini mentioned as preferred AI by user
- **Free Tier**: 15 requests/minute free, sufficient for family use (recommendation generation on-demand)
- **Context Awareness**: Gemini can process quest history, location, weather to create personalized recommendations
- **Flutter SDK**: Official `google_generative_ai` package simplifies integration
- **Offline Graceful Degradation**: If no internet, fall back to static seasonal recommendations

**Alternatives Considered**:
- **Local AI (TFLite)**: Rejected as too complex for simple recommendation logic
- **Rule-Based System**: Considered as fallback; AI provides richer personalization
- **OpenAI**: Rejected due to user preference for Gemini and similar pricing

### 5. Location Services: Browser Geolocation API (Optional/Degraded)

**Decision**: Use Browser Geolocation API via `geolocator_web` with graceful degradation

**Rationale**:
- **Desktop Reality**: Desktop/laptop GPS accuracy poor or unavailable (typically WiFi triangulation, 500m+ error)
- **Optional Feature**: GPS treated as **enhancement**, not requirement (FR-004 changed from MUST to SHOULD)
- **Permission**: Browser prompts for geolocation permission; user can deny without breaking app
- **Fallback Primary**: Virtual exploration via Google Maps Street View is **primary quest completion method**
- **Photo-Only Mode**: Kids can complete quests via webcam photo verification alone

**Accuracy Expectations**:
- **Mobile browsers**: 10-50m accuracy (if device has GPS chip) - rare on family computer
- **Desktop browsers**: 500m-5km accuracy (WiFi triangulation) - common case
- **No GPS**: Graceful degradation to virtual exploration only

**Implementation Strategy**:
```dart
// Attempt geolocation, but don't block UI if unavailable
Future<Position?> tryGetLocation() async {
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Don't request - user can enable later in settings
      return null; 
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium, // ~100m acceptable
      timeLimit: Duration(seconds: 5), // Fail fast
    );
  } catch (e) {
    // Geolocation unavailable/denied - use virtual exploration
    return null;
  }
}
```

**Alternatives Considered**:
- **IP Geolocation**: Rejected; city-level accuracy useless for quest proximity
- **Manual Address Entry**: Considered for future; Street View exploration simpler
- **Require GPS**: Rejected; would exclude desktop users entirely

### 6. Image Handling: MediaDevices API (Webcam Capture)

**Decision**: Use `image_picker_for_web` for webcam photo capture with JPEG compression

**Rationale**:
- **Desktop Camera**: Family computer webcam (not mobile rear camera)
- **Delayed Workflow**: Kids complete virtual exploration → go shopping → bring product home → take photo with webcam
- **Flutter Abstraction**: `image_picker_for_web` wraps browser MediaDevices API (`getUserMedia`)
- **Privacy**: Browser permission prompt, camera indicator LED, user in control
- **Compression**: JPEG quality 85%, target <200KB per photo for LocalStorage efficiency
- **HTTPS Required**: Webcam access requires HTTPS (localhost exempt for development)

**Workflow Example**:
1. Child explores Reggio Calabria market in Google Maps Street View
2. Learns about Bergamotto (citrus fruit)
3. Family goes shopping together (physical or online)
4. Brings Bergamotto home
5. Opens app → "Complete Quest" → Webcam capture photo → Quest marked complete

**Implementation Strategy**:
```dart
import 'package:image_picker_for_web/image_picker_for_web.dart';

Future<Uint8List?> captureWebcamPhoto() async {
  final picker = ImagePickerPlugin();
  final XFile? image = await picker.getImageFromSource(
    source: ImageSource.camera, // Triggers webcam
  );
  if (image == null) return null;
  
  // Compress to <200KB
  final bytes = await image.readAsBytes();
  return await FlutterImageCompress.compressWithList(
    bytes,
    quality: 85,
    format: CompressFormat.jpeg,
  );
}
```

**Browser Compatibility**:
- Chrome/Edge: Full support (getUserMedia)
- Firefox: Full support
- Safari: Full support (macOS 11+)
- Requires HTTPS in production (Let's Encrypt free certificates)

**Alternatives Considered**:
- **File Upload**: Considered as fallback; webcam capture more engaging
- **Native Camera App**: N/A for web platform
- **No Compression**: Rejected; uncompressed photos fill LocalStorage quickly (5-10MB limit per origin)

### 7. Export Functionality: PDF Generation

**Decision**: Use `pdf` package for journal exports

**Rationale**:
- **Universal Format**: PDFs viewable on any device, easy to share
- **Layout Control**: Create nicely formatted albums with photos and text
- **Offline Generation**: No internet required for export
- **Parent-Friendly**: Familiar format for preserving family memories

**Alternatives Considered**:
- **HTML Export**: Rejected; less portable than PDF
- **Native Photo Album**: Considered as additional option; PDF primary for cross-platform

### 8. 🗺️ Google Maps Integration: JavaScript API + Street View (CORE FEATURE)

**Decision**: Use `google_maps_flutter_web` package to embed Google Maps JavaScript API with Street View panoramas

**Rationale**:
- **Educational Geography**: Kids can "walk" through Calabrian farmers markets, English orchards, Italian vineyards **virtually** from family computer
- **Accessibility**: Makes 80 global quest locations accessible without physical travel costs
- **Virtual Exploration Primary**: Street View becomes **primary quest completion method** (not GPS fallback) since desktop GPS unreliable
- **Keyboard Navigation**: Arrow keys (↑↓←→) for Street View movement, +/- for zoom - WCAG 2.1 Level AA compliant
- **Custom Markers**: Product-specific icons from existing Python image pipeline (bergamot icons for Bergamotto quests, etc.)
- **Flutter Integration**: `google_maps_flutter_web` wraps JavaScript API seamlessly, same Dart code works for future mobile
- **Free Tier**: 28,000 map loads/month free (Dynamic Maps), ~100 loads/day for family = well within limits

**Educational Value**:
1. **Geography Learning**: Kids learn where seasonal foods grow (Calabria vs South England climates)
2. **Cultural Context**: Virtual exploration of local markets, farms, orchards in quest regions
3. **Seasonal Awareness**: See how environments change across regions (olive groves in Italy, apple orchards in England)
4. **Virtual Travel**: Experience travel without carbon footprint or expense

**Implementation Architecture**:
```dart
// Quest Map Screen - Display all 80 quests
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(38.1095, 15.6470), // Reggio Calabria, Italy
    zoom: 10,
  ),
  markers: _buildQuestMarkers(), // Custom product icons
  onTap: (LatLng position) => _showNearbyQuests(position),
);

Set<Marker> _buildQuestMarkers() {
  return quests.map((quest) => Marker(
    markerId: MarkerId(quest.id),
    position: LatLng(quest.location.lat, quest.location.lng),
    icon: BitmapDescriptor.fromBytes(quest.customIcon), // Bergamot icon, etc.
    onTap: () => _openQuestDetail(quest),
  )).toSet();
}

// Quest Detail Screen - Embed Street View
class QuestStreetView extends StatelessWidget {
  final Quest quest;
  
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(quest.location.lat, quest.location.lng),
        zoom: 18, // Street level
      ),
      onMapCreated: (controller) {
        // Switch to Street View panorama
        controller.setMapType(MapType.streetView);
        controller.animateCamera(CameraUpdate.newLatLng(
          LatLng(quest.location.lat, quest.location.lng),
        ));
      },
      // Keyboard navigation enabled by default in google_maps_flutter_web
    );
  }
}
```

**Performance Targets** (from spec.md FR-026):
- **Map Load**: <5 seconds on broadband (10 Mbps+)
- **Street View Load**: <3 seconds per panorama
- **Marker Rendering**: All 80 quest markers visible without lag
- **Smooth Panning**: 60fps keyboard navigation in Street View

**Quest Completion Flow**:
1. Browse quests on map (satellite view with custom fruit/vegetable markers)
2. Click quest marker → Opens quest detail screen
3. Tap "Explore Location" → Embeds Street View at quest coordinates
4. Navigate with arrow keys through market/orchard (educational exploration)
5. Find seasonal product landmarks (e.g., Bergamotto stalls in Reggio Calabria market)
6. Complete quest via:
   - **Virtual**: Mark as "Explored Virtually" (earns "Virtual Explorer" badge)
   - **Photo**: Webcam capture of product brought home (earns "Seasonal Collector" badge)
   - **GPS**: If geolocation available on mobile browser (rare on desktop)

**Google Maps API Key Management**:
- **Development**: Localhost API key (no restrictions) for testing
- **Production**: Restrict to deployed domain (e.g., `seasonal-quests.web.app`)
- **Billing**: Enable billing alert at $50/month (family will never hit this)
- **Quotas**: Monitor Dynamic Maps (28k/month free) and Street View (28k/month free)

**Keyboard Navigation (WCAG 2.1 Level AA)**:
- **Tab**: Focus next interactive element (markers, zoom controls)
- **Enter/Space**: Activate focused marker
- **Escape**: Close quest detail, return to map overview
- **Arrow Keys**: Navigate Street View panorama (↑ forward, ↓ backward, ← rotate left, → rotate right)
- **+/-**: Zoom in/out on map
- **Focus Indicators**: 2px solid blue outline on focused markers

**Alternatives Considered**:
- **Static Map Images**: Rejected; no virtual exploration, kills educational value
- **OpenStreetMap**: Rejected; no Street View equivalent, less kid-friendly
- **Mapbox**: Rejected; more expensive, no Street View
- **Apple Maps**: Rejected; Look Around limited coverage in Italy
- **No Maps**: Rejected; GPS-only would exclude desktop users entirely

**Data Model Impact**:
```dart
class QuestLocation {
  final String locationName; // "Reggio Calabria Farmers Market"
  final double lat;          // 38.1095
  final double lng;          // 15.6470
  final String? streetViewPanoId; // Optional: specific panorama ID for consistency
}

class VirtualExplorationSession {
  final String questId;
  final DateTime exploredAt;
  final int durationSeconds; // Time spent in Street View
  final bool markedComplete; // true if marked as "Explored Virtually"
}
```

**Privacy Considerations**:
- No Google Analytics tracking (Maps API separate from GA)
- No user location sent to Google (only quest locations hardcoded in app)
- Street View images cached in browser (no repeated API calls)
- API key restricted to app domain only

## Child-Safe UX Best Practices (Web/Desktop Optimized)

### Large Click Targets (Keyboard + Mouse)
- **Minimum Size**: 48x48px (WCAG 2.1 AAA guideline for pointer targets)
- **Spacing**: 8px minimum between interactive elements
- **Buttons**: Extra large (64x64px) for primary actions like "Start Quest"
- **Hover States**: Clear visual feedback (background color change, cursor pointer)
- **Focus Indicators**: 2px solid outline for keyboard navigation (Tab key)

### Stress-Free Design Patterns
- **No Timers**: No countdown clocks or time pressure mechanics
- **Gentle Colors**: Pastel palette (soft greens, blues, yellows) instead of bright reds
- **Positive Feedback**: Always encouraging messages, never punitive language
- **No Dark Patterns**: No tricks, no hidden costs, no manipulative mechanics
- **Clear Visual Hierarchy**: Icons + text labels, not icons alone

### Simple Navigation (Desktop Layout)
- **Sidebar Navigation**: Max 3-4 main sections (Quests, Progress, Journal, Settings) instead of bottom nav
- **Back Button**: Always visible in top-left, keyboard shortcut (Alt+←)
- **Breadcrumbs**: Clear indication of where child is in app (Home > Quests > Bergamotto)
- **Confirmation Dialogs**: For destructive actions only (e.g., delete journal entry)
- **Escape Key**: Universal "go back" shortcut

### Accessibility Considerations (WCAG 2.1 Level AA)
- **Font Sizes**: Minimum 16px for body text, 20px for headings
- **Contrast Ratios**: WCAG AA compliance (4.5:1 for text)
- **Screen Reader Support**: Semantic HTML labels for all interactive elements (aria-label, role attributes)
- **Keyboard Navigation**: 100% keyboard accessible (Tab, Enter, Escape, Arrow keys)
  - **Tab Order**: Logical flow (left-to-right, top-to-bottom)
  - **Skip Links**: "Skip to main content" for screen readers
  - **Focus Management**: Trap focus in modals, return focus after closing
- **High Contrast Mode**: Test in Windows High Contrast mode
- **Zoom Support**: Layout usable at 200% browser zoom

## Privacy & Safety Patterns

### Local-First Data Architecture (Browser-Based)
- All quest data, photos, progress stored in **Browser LocalStorage + IndexedDB**
- **LocalStorage**: Settings, user progress (JSON text, 5-10MB limit per origin)
- **IndexedDB**: Quest photos (binary Blob storage, ~50MB typical quota)
- **No Cloud Sync**: All data stays on local computer, never transmitted to servers
- **Export Option**: PDF journal exports for backup (manual, parent-controlled)

**Storage Locations** (browser-managed):
```
Browser LocalStorage:
├── seasonal_quests_settings          # JSON: theme, language, AI opt-in
├── seasonal_quests_user_progress     # JSON: completed quests, badges
└── seasonal_quests_journal_entries   # JSON: journal metadata

IndexedDB (objectStore: "photos"):
├── {uuid-1}.jpg   # Compressed webcam photos (~100-200KB each)
└── {uuid-2}.jpg
```

### Permission Management (Browser-Native)
- **Geolocation**: Browser prompts on first request; app works without approval (virtual exploration fallback)
- **Camera**: Browser prompts on first webcam access; LED indicator always visible
- **Storage**: No permission needed (LocalStorage/IndexedDB automatic per-origin)
- **HTTPS Required**: Webcam and Geolocation require secure context (localhost exempt for dev)

**Child-Friendly Permission Dialogs**:
```dart
// Example: Geolocation permission explanation
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('📍 Help Us Find Nearby Quests'),
    content: Text(
      'We need your location to show quests near you. '
      'If you prefer, you can explore quests virtually on the map instead!',
    ),
    actions: [
      TextButton(
        child: Text('Explore Virtually'),
        onPressed: () => Navigator.pop(context, false),
      ),
      ElevatedButton(
        child: Text('Allow Location'),
        onPressed: () async {
          Navigator.pop(context, true);
          await Geolocator.requestPermission();
        },
      ),
    ],
  ),
);
```

### COPPA Compliance (Children's Online Privacy Protection Act)
- **No Data Collection**: Zero server-side tracking, no analytics, no user accounts
- **No Third-Party SDKs**: Except Google Maps (map tiles only, no user tracking) and Gemini AI (explicit parent opt-in)
- **No Advertising**: Family educational app, no ads or monetization
- **Parental Controls**: AI recommendations require parent password to enable
### COPPA Compliance (Children's Online Privacy Protection Act)
- **No Data Collection**: Zero server-side tracking, no analytics, no user accounts
- **No Third-Party SDKs**: Except Google Maps (map tiles only, no user tracking) and Gemini AI (explicit parent opt-in)
- **No Advertising**: Family educational app, no ads or monetization
- **Parental Controls**: AI recommendations require parent password to enable
- **Age Gate**: (Optional) Ask parent birthdate on first launch to document parental consent

## Performance Optimization Strategies (Web-Specific)

### Startup Time (<3 seconds on broadband)
- **Code Splitting**: Split Flutter Web build into chunks (deferred loading)
- **Lazy Load Images**: Quest images load on scroll, not upfront
- **Service Worker Caching**: Cache compiled WASM + quest data for instant repeat visits
- **Preload Critical Assets**: Google Maps JavaScript API, core fonts, hero images
- **Minimize main()**: Defer non-critical initialization to post-render

### Data Access Patterns (Browser Storage)
- **LocalStorage**: Load `user_progress.json` once at startup, keep in memory, debounce saves
- **IndexedDB**: Lazy load photos (only when viewing journal screen)
- **Quest Data**: Bundle in app assets (`assets/quests_calabria.json`), load once and cache in memory
- **Google Maps**: Browser caches map tiles automatically (HTTP cache headers)

### Browser I/O Performance
- **JSON Parsing**: Use `compute()` to parse large JSON on Web Worker (avoid main thread blocking)
- **Atomic Writes**: LocalStorage setItem is atomic (no corruption risk)
- **Debounce Saves**: Auto-save user progress after 2 seconds of inactivity (not every change)
- **IndexedDB Transactions**: Batch photo saves in single transaction for speed

### Smooth Rendering (60fps)
- **CanvasKit Renderer**: Default for Flutter Web, hardware-accelerated via WebGL
- **`AnimatedContainer`**: Use for smooth transitions (avoid rebuilding entire tree)
- **`RepaintBoundary`**: Isolate complex widgets (Google Maps embed) to prevent full repaints
- **Profile**: Chrome DevTools Performance tab to catch jank

### Network Efficiency (Google Maps API)
- **Map Load**: <5s on 10 Mbps broadband (target from FR-026)
- **Street View**: <3s per panorama load
- **Tile Caching**: Browser HTTP cache keeps map tiles for 7 days (reduces API calls)
- **Marker Bundling**: Load all 80 quest markers in single batch (not one-by-one)
- **Quota Monitoring**: Google Cloud Console alerts if approaching 28k/month free tier limit

### Storage Management (Browser Quotas)
- **LocalStorage Limit**: 5-10MB per origin (sufficient for JSON text data)
- **IndexedDB Quota**: ~50MB typical (browsers prompt if exceeding; store ~250 compressed photos)
- **Photo Compression**: JPEG quality 85%, target <200KB per photo
- **Periodic Cleanup**: Offer "Delete Old Photos" button in settings (user-controlled)
- **Estimate**: ~2MB app bundle + ~200KB quest data + ~50MB photos (250 quests) = ~52MB total

## Integration Patterns

### Gemini AI Recommendation Flow
1. **Trigger**: User taps "Get Recommendations" button
2. **Context Gathering**: Collect user's completed quests, current location, weather
3. **Prompt Construction**: Build personalized prompt for Gemini
4. **API Call**: Send to Gemini 1.5 Flash (free tier, <1s response)
5. **Result Parsing**: Extract 3-5 recommended quest IDs
6. **Fallback**: If offline or API fails, use rule-based seasonal filtering
7. **Cache**: Store recommendations for 24 hours (avoid repeated API calls)

**Example Prompt Template**:
```
You are a family educator helping children explore seasonal foods and nature. 
Based on this family's activity:
- Completed quests: [list of 5 most recent]
- Current season: Autumn
- Location: Calabria, Italy
- Weather: Sunny, 22°C
- Child interests: Fruits (completed 8), Vegetables (completed 2)

Recommend 3 new quests from this list that would:
1. Diversify learning (suggest vegetables/flowers since fruits are well-covered)
2. Match current weather (outdoor activities in sunny weather)
3. Be seasonally appropriate for autumn in Calabria
4. Build on previous learning with new related topics

Available quests: [JSON array of uncompleted quests]

Return only quest IDs as JSON array: ["quest_id_1", "quest_id_2", "quest_id_3"]
```

### Weather Integration (Optional Phase 2)
- Use free weather API (OpenWeatherMap or WeatherAPI.com)
- Cache weather for 1 hour
- Simple logic: rainy → indoor quests, sunny → outdoor quests
- Fallback: If no weather data, show all quests

## Testing Strategy

### Widget Tests (Child-Facing UI)
- Quest card displays correct information
- Large buttons respond to taps
- Navigation flows work correctly
- Animations smooth and non-jarring

### Integration Tests (Critical Flows)
- Complete a quest end-to-end (select → check-in → photo → complete)
- Earn a badge after completing first quest
- Create journal entry with photo
- Export journal to PDF

### Unit Tests (Business Logic)
- Badge award logic (streaks, milestones)
- Quest filtering by season/category
- GPS distance calculations (50-150m tolerance)
- Image compression quality

### Manual Testing (Family UAT)
- Let children use app for real quests
- Observe usability issues (confusion, frustration)
- Verify educational content is age-appropriate
- Check battery impact during outdoor sessions

## Deployment Considerations (Flutter Web)

### Platform Requirements
- **Browsers**: Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
- **Target Resolution**: 1366x768 (most common laptop screen) up to 1920x1080
- **Minimum Connection**: 10 Mbps broadband for Google Maps (app works offline after initial load)
- **HTTPS Required**: For webcam (MediaDevices API) and geolocation access (localhost exempt for dev)

### Build Configuration
- **Development**: 
  ```bash
  flutter run -d chrome  # Hot reload enabled
  flutter run -d web-server --web-port=8080  # Test on multiple browsers
  ```
- **Production**:
  ```bash
  flutter build web --release --web-renderer canvaskit
  # Outputs to build/web/
  # Includes WASM, compiled Dart, and assets
  ```
- **Assets**: 
  - Pre-generated seasonal images from Python pipeline bundled in `web/assets/images/`
  - Quest data JSON in `web/assets/data/quests_calabria.json`
  - Google Maps API key in `web/index.html` (production key, domain-restricted)

### Hosting Options
**Option 1: Firebase Hosting** (RECOMMENDED)
- **Pros**: Free tier generous (10GB transfer/month), auto HTTPS, global CDN, easy deployment
- **Setup**:
  ```bash
  firebase init hosting
  # Set public directory to: build/web
  firebase deploy
  ```
- **Custom Domain**: Connect `seasonal-quests.family` (optional)
- **Cost**: $0/month for family use (well within free tier)

**Option 2: GitHub Pages**
- **Pros**: Free, integrated with Git workflow
- **Cons**: No server-side logic (fine for static SPA), slower than Firebase CDN
- **Setup**: 
  ```bash
  flutter build web --base-href "/seasonal-quest-web/"
  # Push build/web/ to gh-pages branch
  ```

**Option 3: Vercel/Netlify**
- **Pros**: Automatic deployments on git push, preview URLs for testing
- **Cons**: Slightly more complex setup than Firebase
- **Cost**: Free tier sufficient

### Distribution (Family Use)
- **URL Sharing**: Send `https://seasonal-quests.web.app` to family members
- **Bookmark**: Add to browser bookmarks or home screen (PWA install prompt)
- **Offline**: Service Worker caches app for offline use after first visit
- **Updates**: Automatic on next page reload (no app store approval needed)

### Progressive Web App (PWA) Setup
Add to `web/manifest.json`:
```json
{
  "name": "Seasonal Quest Explorer",
  "short_name": "Seasonal Quest",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#E8F5E9",
  "theme_color": "#4CAF50",
  "description": "Explore seasonal foods and nature with your family",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

**Install Prompt**: Browsers automatically show "Add to Home Screen" after 2+ visits

### Environment Variables (API Keys)
**Development** (`.env` file, gitignored):
```
GOOGLE_MAPS_API_KEY=AIzaSy...localhost_key
GEMINI_API_KEY=AIzaSy...dev_key
```

**Production** (Firebase environment config or hardcoded in `web/index.html`):
```html
<script>
  window.GOOGLE_MAPS_API_KEY = "AIzaSy...production_key_restricted_to_domain";
</script>
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSy...&libraries=places"></script>
```

### Monitoring & Analytics (Optional, Privacy-Conscious)
- **No Google Analytics**: Violates privacy-first principle
- **Server Logs Only**: Firebase Hosting logs show page views (no user tracking)
- **Error Tracking**: (Optional) Self-hosted Sentry for crash reports (parental opt-in)

## Migration from Existing System

### Leveraging Existing Assets
The project already has a Python-based image generation pipeline:
- **Reuse**: Pre-generated seasonal images (icons, story scenes, recipes)
- **Integration**: Bundle images in `assets/` directory during Flutter build
- **Mapping**: Use existing `images_mapping.json` to link products to images
- **Content**: Import `seasonal_db_complete_story_cards__WITH_3x_stories_20250813_101620.json` as quest data source

### Quest Data Transformation
Transform existing JSON structure to Flutter-compatible format:
- Extract `products` array from JSON
- Map `name_it`/`name_en` to quest titles
- Use `stories.Calabria.it[0]` as quest description
- Pull `educational_text` for learning content
- Reference `icon` filename for quest card image

**Example Transformation** (pseudocode):
```python
# Input: seasonal_db_complete_story_cards__WITH_3x_stories_20250813_101620.json
# Output: assets/data/quests_calabria.json

for product in json_data['products']:
    quest = {
        'id': product['id'],
        'title_it': product['it'],
        'title_en': product['en'],
        'description_it': product['stories']['Calabria'][0]['it'],
        'description_en': product['stories']['Calabria'][0]['en'],
        'category': product['category'],
        'season': derive_season_from_harvest_months(product['harvest_months']),
        'educational_content_it': product['educational_text']['Calabria']['it'],
        'educational_content_en': product['educational_text']['Calabria']['en'],
        'icon_path': f'assets/images/icons/{product["icon"]}',
        'story_image_path': f'assets/images/story_scenes/{product["en"].lower()}_story1.png',
        'difficulty': 'medium',  # Default, can be refined
        'estimated_time': 15,  # minutes, default
        'character': 'Lina'  # Assign recurring characters to quests
    }
```

## Summary

**Platform**: Flutter Web 3.16+ (web-first, desktop/laptop browsers)  
**Tech Stack**: Flutter Web + Riverpod + LocalStorage/IndexedDB + Google Maps JavaScript API + Gemini AI  
**Architecture**: Offline-capable PWA, privacy-by-default, keyboard-accessible, WCAG 2.1 Level AA  
**Core Feature**: 🗺️ Google Maps Street View virtual exploration (primary quest completion method)  
**Storage**: Browser LocalStorage (JSON) + IndexedDB (photos) - no cloud, no database  
**User Context**: Kids ages 5-12 on family desktop/laptop computer (supervised use)  
**Key Patterns**: Virtual exploration, webcam photo verification, local-only data, gentle gamification  
**Migration**: Leverage existing Python-generated assets (icons, story scenes) + quest JSON  
**Deployment**: Firebase Hosting (free tier) with PWA support for offline use  
**Focus**: Simple, stress-free educational experience combining geography + seasonal food learning  
**Code Reuse**: 90% of Dart codebase reusable for future mobile apps (Phase 8) when kids allowed devices

All technical decisions prioritize child safety, offline capability, and ease of use over technical sophistication. The architecture supports the MVP scope while remaining extensible for Phase 2/3 features (weather integration, custom groups) if needed.
