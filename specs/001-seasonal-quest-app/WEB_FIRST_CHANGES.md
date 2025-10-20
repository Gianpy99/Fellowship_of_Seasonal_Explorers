# Web-First Architecture Changes

**Date**: 2025-10-20  
**Reason**: Kids use family desktop/laptop computer, not allowed personal mobile/tablet devices yet  
**Impact**: Complete platform shift from mobile-first to web-first

---

## Platform Priority Change

### Before (Mobile-First)
- **Primary Platform**: iOS + Android native apps
- **Framework**: Flutter mobile
- **Devices**: Phones and tablets
- **Context**: Family outings with mobile devices

### After (Web-First) ✅
- **Primary Platform**: Web app (desktop/laptop browsers)
- **Framework**: Flutter Web OR React/Next.js (TBD in research)
- **Devices**: Desktop, laptop (family computer)
- **Context**: Kids using family computer for educational activities
- **Future**: Mobile/tablet apps when kids are allowed devices

---

## Technical Stack Changes

### Storage
- **Before**: JSON files via `path_provider` (mobile file system)
- **After**: Browser LocalStorage + IndexedDB (web storage APIs)
- **Note**: Still JSON format, just different persistence mechanism

### Location Services
- **Before**: `geolocator` package (native GPS)
- **After**: Browser Geolocation API (web standard)
- **Note**: Less reliable on desktop/laptop (many don't have GPS), so manual check-in becomes primary method

### Camera
- **Before**: `image_picker` + `flutter_image_compress` (native camera)
- **After**: MediaDevices API (`getUserMedia`) for browser camera/webcam
- **Note**: Requires HTTPS for camera permissions

### Dependencies (Flutter Web)
```yaml
# Remove mobile-specific:
# - geolocator
# - image_picker
# - path_provider (native)

# Add web-specific:
  flutter_web_plugins:
    sdk: flutter
  universal_html: ^2.2.4
  image_picker_for_web: ^3.0.1
  flutter_image_compress_web: ^0.1.4
  # Keep: riverpod, google_generative_ai, pdf, uuid, intl
```

### ✅ DECISION: Flutter Web (Selected)

**Rationale**:
- 90% code reuse for future mobile apps (Phase 8)
- Single Dart codebase for web + mobile
- Existing Flutter expertise from plan.md
- Better offline support with Service Workers
- Google Maps JavaScript API integration via `google_maps_flutter_web`

**Dependencies (Flutter Web Final)**:
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_web_plugins:
    sdk: flutter
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0
  
  # Web storage
  shared_preferences: ^2.2.2  # Simple settings
  
  # Google Maps integration
  google_maps_flutter: ^2.5.0
  google_maps_flutter_web: ^0.5.4
  
  # Web-specific
  universal_html: ^2.2.4
  image_picker_for_web: ^3.0.1
  flutter_image_compress_web: ^0.1.4
  
  # AI and utilities
  google_generative_ai: ^0.2.0
  pdf: ^3.10.7
  uuid: ^4.1.0
  intl: ^0.18.1
```

---

## UX Changes (Desktop/Laptop Focus)

### Interaction Patterns
- **Before**: Touch targets (48x48dp minimum), swipe gestures
- **After**: Click targets (48x48px minimum), keyboard navigation (Tab/Enter/Escape)
- **New**: Hover states, right-click context menus (optional)

### Layout
- **Before**: Mobile portrait/landscape responsive
- **After**: Desktop responsive (1024px+ primary, scales down to 768px)
- **Viewport**: Optimized for 1366x768 (common laptop resolution)

### Accessibility
- **Before**: Touch accessibility (large targets)
- **After**: Keyboard accessibility (WCAG 2.1 Level AA)
  - Tab navigation between all interactive elements
  - Enter/Space to activate buttons
  - Escape to close modals
  - Arrow keys for lists/carousels

### Camera Usage
- **Before**: Rear camera for taking photos outdoors
- **After**: Webcam for taking photos at home (product brought home, photo taken later)
- **Workflow Change**: 
  - Kids find seasonal product at market/store
  - Bring home to family computer
  - Complete quest with webcam photo
  - OR: Manual check-in becomes primary method (no GPS/camera required)

---

## Feature Priority Adjustments

### GPS Check-In with Google Maps ✨ NEW FEATURE
- **Before**: Primary completion method (mobile GPS accurate)
- **After**: Interactive Google Maps experience on web
- **New Feature**: Kids can "walk" in Google Maps Street View to explore quest locations
- **Workflow**:
  1. Quest shows target location on Google Maps (satellite + street view)
  2. Kids navigate Street View to "explore" the area (like a virtual field trip)
  3. Find landmarks/markers related to seasonal product (e.g., farmers market, orchard)
  4. Complete quest by "visiting" location in Street View
  5. **Alternative**: If browser has GPS, validate actual location proximity
- **Educational Value**: Learn geography, explore distant regions (South England from Calabria!)

### Photo Capture
- **Before**: Mobile camera at location
- **After**: Webcam at home (delayed capture workflow)
- **Alternative**: Upload photos from phone via file input

### Offline Mode
- **Before**: Full offline with mobile file system
- **After**: Limited offline with Service Workers (PWA)
- **Caching**: Cache quests + images for offline browsing
- **Sync**: Save progress to LocalStorage, no cloud sync needed

---

## File Structure Changes

### Web-Specific Additions
```
seasonal_quest_app/
├── web/
│   ├── index.html              # Entry point
│   ├── manifest.json           # PWA manifest (optional)
│   ├── service-worker.js       # Offline caching (optional)
│   └── icons/                  # PWA app icons
├── lib/
│   ├── services/
│   │   ├── storage_service_web.dart      # LocalStorage wrapper
│   │   ├── geolocation_service_web.dart  # Browser Geolocation API
│   │   └── camera_service_web.dart       # MediaDevices API
│   └── ...
```

### Remove Mobile-Specific
```
# No longer needed for web-first:
├── android/        # Remove or defer to Phase 8
├── ios/            # Remove or defer to Phase 8
├── integration_test/  # Flutter integration tests (use web E2E instead)
```

---

## Development Phase Updates

### Phase 0: Research & Technical Prototypes ✅ DECISION MADE

**Framework Decision**: ✅ **Flutter Web Selected**
- Reason: 90% code reuse for future mobile apps, single Dart codebase, excellent offline support

**Prototypes to Build**:
1. **Google Maps Integration** (PRIORITY)
   - [ ] Test `google_maps_flutter_web` package
   - [ ] Embed Google Maps with quest markers
   - [ ] Test Street View API integration
   - [ ] Verify keyboard navigation in Street View (arrow keys)
   - [ ] Test embedding custom POI markers (quest locations)

2. **Browser Geolocation API**
   - [ ] Test on desktop/laptop (Chrome, Firefox, Safari)
   - [ ] Measure accuracy (expect 100-1000m range on WiFi)
   - [ ] Test HTTPS requirement for permissions
   - [ ] Build fallback UI for "Geolocation unavailable"

3. **MediaDevices API (Webcam)**
   - [ ] Test `getUserMedia` for webcam access
   - [ ] Test image capture and compression
   - [ ] Verify HTTPS requirement
   - [ ] Build permission request flow

4. **LocalStorage Performance**
   - [ ] Store 80+ quests JSON (estimate ~200KB)
   - [ ] Benchmark parse time on startup
   - [ ] Test `shared_preferences` for settings
   - [ ] Verify offline persistence

5. **Keyboard Navigation**
   - [ ] Test Tab order through quest cards
   - [ ] Test Enter/Space for button activation
   - [ ] Test Escape for modal close
   - [ ] Test arrow keys in Google Maps

### Phase 1: Data Layer (No Changes)
- JSON models same for web/mobile
- Just change storage implementation (LocalStorage vs file system)

### Phase 2: UI Scaffold (Web-Focused)
- [ ] Desktop-first responsive layout (1366x768 target)
- [ ] Keyboard navigation (Tab/Enter/Escape)
- [ ] Mouse hover states
- [ ] WCAG AA color contrast

### Phase 3: Quest System with Google Maps ✨
- [ ] **Google Maps Quest Explorer**
  - [ ] Embed Google Maps on quest detail screen
  - [ ] Show quest location marker with custom icon (fruit/vegetable)
  - [ ] Enable Street View mode for virtual exploration
  - [ ] Add "Explore in Street View" button
  - [ ] Mark quest as "visited" when user navigates Street View near location
- [ ] **Geolocation Check-in** (Optional)
  - [ ] Browser Geolocation API with accuracy indicator
  - [ ] Show "You are within 500m" confirmation
  - [ ] Fallback: "GPS not available, use Street View instead"
- [ ] **Photo Capture**
  - [ ] Webcam capture via MediaDevices API
  - [ ] File upload option for mobile photos
  - [ ] Save compressed JPEG to LocalStorage/IndexedDB
- [ ] **Completion Methods**
  - [ ] Method 1: Street View exploration + photo (primary)
  - [ ] Method 2: GPS check-in + photo (if available)
  - [ ] Method 3: Photo only (manual check-in)

### Phase 8: Mobile Apps (NEW - Future)
- [ ] Add native mobile dependencies
- [ ] Build iOS/Android apps when kids allowed devices
- [ ] Reuse 90% of codebase (if using Flutter)

---

## Testing Strategy Changes

### Before (Mobile)
- Widget tests (Flutter)
- Integration tests on emulators

### After (Web)
- Component tests (Flutter Web or React Testing Library)
- E2E tests with Playwright/Cypress
- Cross-browser testing (Chrome, Firefox, Safari)
- Keyboard navigation testing
- Screen reader testing (NVDA/JAWS)

---

## Deployment Changes

### Before (Mobile)
- App Store + Google Play
- App updates via stores

### After (Web)
- **Hosting**: Netlify, Vercel, or GitHub Pages
- **Domain**: Optional custom domain (e.g., seasonal-explorers.family)
- **Updates**: Instant deployment (no app store approval)
- **Installation**: Optional PWA install (Add to Home Screen)

### Future (Mobile Apps)
- Build from same codebase when kids ready for devices
- Deploy to stores as Phase 8

---

## Benefits of Web-First Approach

1. **Instant Access**: No app store downloads, just URL
2. **Instant Updates**: Push fixes immediately, no waiting for approval
3. **Cross-Platform**: Works on Windows, Mac, Linux (any browser)
4. **Family Context**: Perfect for kids using supervised family computer
5. **Future-Proof**: Easy to add mobile apps later (90% code reuse with Flutter)
6. **No Installation**: Parents don't need to manage app installs
7. **Accessibility**: Better screen reader support, keyboard navigation
8. **Google Maps Integration**: Virtual exploration of quest locations worldwide (educational!)
9. **Street View Learning**: Kids can "visit" Calabria markets or English orchards from home
10. **No GPS Required**: Street View makes quests accessible without physical location

---

## Risks & Mitigations

### Risk: GPS unavailable on desktop
- **Mitigation**: Manual check-in becomes primary method (photo-only verification)

### Risk: Webcam quality lower than mobile camera
- **Mitigation**: Accept any photo, focus on engagement not quality

### Risk: Kids might want mobile experience later
- **Mitigation**: Flutter Web allows easy port to mobile (Phase 8)

### Risk: Browser compatibility issues
- **Mitigation**: Test on Chrome, Firefox, Safari; use polyfills for older browsers

---

## Next Steps

1. ✅ Update `plan.md` with web-first technical context
2. ✅ Update `spec.md` with desktop/laptop user context
3. ✅ Update `research.md` with browser API research
4. ✅ Update `data-model.md` (already JSON-based, minimal changes)
5. ✅ Update `quickstart.md` for Flutter Web setup
6. ⏭️ **Phase 0 Decision**: Confirm Flutter Web vs React/Next.js
7. ⏭️ Begin web-first development

---

**Status**: Architecture pivot complete. Ready for Phase 0 research decision on Flutter Web vs React.
