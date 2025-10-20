# Phase 0 Prototypes - Flutter Web Setup

**Status**: ⚠️ Requires Flutter SDK installation  
**Purpose**: Validate Google Maps + Browser APIs before full development  
**Reference**: See `specs/001-seasonal-quest-app/PHASE0_PROTOTYPES.md` for full specifications

## Prerequisites

### 1. Install Flutter SDK

```powershell
# Download from https://flutter.dev/docs/get-started/install/windows
# Or use Chocolatey:
choco install flutter

# Verify installation
flutter --version  # Should show 3.16+
flutter doctor      # Check for missing dependencies
```

### 2. Enable Flutter Web

```powershell
flutter channel stable
flutter upgrade
flutter config --enable-web
flutter doctor -v   # Verify "Chrome" detected
```

### 3. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create project: "Seasonal Quest Prototypes"
3. Enable APIs:
   - **Maps JavaScript API**
   - **Street View Static API**
   - **Geolocation API**
4. Create credentials → API Key
5. Restrict key:
   - Application: HTTP referrers → `http://localhost:*`
   - API: Select all 3 APIs above

## Quick Start

Once Flutter is installed:

```powershell
cd C:\Development\Fellowship_of_Seasonal_Explorers\prototypes\phase0_web

# Create Flutter Web project (one-time)
flutter create --platforms=web .

# Add Google Maps API key to web/index.html
# (See "Configuration" section below)

# Run Prototype 1: Google Maps
flutter run -d chrome lib/prototype_1_google_maps.dart

# Run Prototype 2: Geolocation
flutter run -d chrome lib/prototype_2_geolocation.dart

# Run Prototype 3: Webcam
flutter run -d chrome lib/prototype_3_webcam.dart

# Run Prototype 4: LocalStorage
flutter run -d chrome lib/prototype_4_localstorage.dart

# Run Prototype 5: Keyboard Navigation
flutter run -d chrome lib/prototype_5_keyboard_nav.dart
```

## Configuration

### Edit `web/index.html`

Add before `</head>`:

```html
<!-- Google Maps JavaScript API -->
<script>
  window.GOOGLE_MAPS_API_KEY = "YOUR_API_KEY_HERE";
</script>
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE&libraries=places,geometry" defer></script>
```

### Edit `pubspec.yaml`

```yaml
name: phase0_prototypes
description: Technical validation prototypes for Seasonal Quest Web App

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_web_plugins:
    sdk: flutter
  
  # Google Maps
  google_maps_flutter: ^2.5.0
  google_maps_flutter_web: ^0.5.4
  
  # Browser APIs
  image_picker_for_web: ^3.0.1
  geolocator: ^10.1.0
  geolocator_web: ^2.2.0
  shared_preferences: ^2.2.2
  shared_preferences_web: ^2.2.1
  
  # Utilities
  intl: ^0.18.1
```

Then run:
```powershell
flutter pub get
```

## Prototypes Overview

### ✅ Prototype 1: Google Maps Integration (PRIORITY)
**File**: `lib/prototype_1_google_maps.dart`  
**Tests**:
- TC1: Display quest markers on map
- TC2: Street View integration with keyboard navigation
- TC3: Custom markers (product icons)

**Success Criteria**:
- Map loads <5 seconds
- Street View loads <3 seconds
- Keyboard navigation works (arrow keys, +/-)

---

### ✅ Prototype 2: Browser Geolocation API
**File**: `lib/prototype_2_geolocation.dart`  
**Tests**:
- TC1: Request location permission
- TC2: Get current position (expect low accuracy on desktop)
- TC3: Graceful degradation when GPS unavailable

**Success Criteria**:
- Permission prompt appears
- Location retrieved (500m+ accuracy acceptable)
- App works without GPS

---

### ✅ Prototype 3: MediaDevices API (Webcam)
**File**: `lib/prototype_3_webcam.dart`  
**Tests**:
- TC1: Request webcam permission
- TC2: Capture photo
- TC3: Compress to <200KB JPEG

**Success Criteria**:
- Webcam LED indicator activates
- Photo saved to IndexedDB
- <1 second capture time

---

### ✅ Prototype 4: LocalStorage Performance
**File**: `lib/prototype_4_localstorage.dart`  
**Tests**:
- TC1: Save 80 quest completions (~200KB JSON)
- TC2: Load and parse JSON
- TC3: Benchmark read/write speed

**Success Criteria**:
- <100ms to save JSON
- <50ms to load and parse JSON
- No data corruption

---

### ✅ Prototype 5: Keyboard Navigation (WCAG 2.1 Level AA)
**File**: `lib/prototype_5_keyboard_nav.dart`  
**Tests**:
- TC1: Tab navigation through UI
- TC2: Enter/Space to activate buttons
- TC3: Escape to close modals
- TC4: Arrow keys in lists

**Success Criteria**:
- 100% keyboard accessible
- Visible focus indicators (2px blue outline)
- Logical tab order

---

## Next Steps After Validation

1. ✅ All prototypes pass → Proceed to Phase 1 (data models)
2. ❌ Google Maps fails → Consider static maps or OpenStreetMap
3. ❌ Webcam fails → Fall back to file upload
4. ❌ LocalStorage fails → Investigate IndexedDB only

## Troubleshooting

### "Google Maps JavaScript API error: InvalidKeyMapError"
→ Check API key restrictions in Google Cloud Console

### "getUserMedia is not a function"
→ Must run on HTTPS (or localhost for dev)

### "flutter: command not found"
→ Add Flutter SDK to PATH:
```powershell
$env:Path += ";C:\flutter\bin"
```

### Map loads but Street View missing
→ Enable "Street View Static API" in Google Cloud Console

## Reference Documents

- **Full Specifications**: `specs/001-seasonal-quest-app/PHASE0_PROTOTYPES.md`
- **Research Decisions**: `specs/001-seasonal-quest-app/research.md`
- **Data Model**: `specs/001-seasonal-quest-app/data-model.md`
