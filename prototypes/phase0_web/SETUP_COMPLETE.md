# ✅ Phase 0 Prototypes - Setup Complete

**Date**: 2025-10-20  
**Status**: Ready for execution (requires Flutter SDK installation)

---

## 📋 What's Been Created

### 1. ✅ Updated `quickstart.md`
**Location**: `specs/001-seasonal-quest-app/quickstart.md`

**Changes**:
- Replaced mobile setup with **Flutter Web setup**
- Added Google Maps API key configuration steps
- Updated dependencies for web (google_maps_flutter_web, image_picker_for_web, geolocator_web)
- Changed project structure to reflect web/browser context
- Updated development workflow (flutter run -d chrome, hot reload, browser DevTools)

### 2. ✅ Updated `plan.md`
**Location**: `specs/001-seasonal-quest-app/plan.md`

**Fixed Sections**:
- **Technical Context**: Updated to Flutter Web 3.16+, browser APIs, LocalStorage/IndexedDB, Google Maps JavaScript API
- **Project Structure**: New directory layout with web/ folder, Google Maps services, webcam services, keyboard navigation utilities
- **Key Constraints**: Desktop/laptop focus, keyboard navigation WCAG 2.1 Level AA, virtual exploration primary

### 3. ✅ Created Prototype Project Structure
**Location**: `prototypes/phase0_web/`

**Files Created**:
```
phase0_web/
├── README.md                           # Complete setup instructions
├── pubspec.yaml                        # Flutter Web dependencies
└── lib/
    ├── prototype_1_google_maps.dart    # Google Maps + Street View integration
    └── prototype_2_geolocation.dart    # Browser Geolocation API testing
```

**Still To Create** (when Flutter installed):
- `prototype_3_webcam.dart` - MediaDevices API webcam capture
- `prototype_4_localstorage.dart` - LocalStorage performance benchmarks
- `prototype_5_keyboard_nav.dart` - WCAG 2.1 keyboard accessibility testing

---

## 🚀 Next Steps (Requires Flutter Installation)

### Step 1: Install Flutter SDK

```powershell
# Option A: Download from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\flutter

# Option B: Use Chocolatey package manager
choco install flutter

# Add to PATH
$env:Path += ";C:\flutter\bin"

# Verify
flutter --version  # Should show 3.16+
flutter doctor     # Check for missing dependencies
```

### Step 2: Enable Web Support

```powershell
flutter channel stable
flutter upgrade
flutter config --enable-web
flutter doctor -v  # Verify "Chrome" detected
```

### Step 3: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create project: "Seasonal Quest Prototypes"
3. Enable APIs:
   - **Maps JavaScript API**
   - **Street View Static API**
   - **Geolocation API**
4. Create API Key
5. Restrict to `http://localhost:*` (development)

### Step 4: Configure Project

```powershell
cd C:\Development\Fellowship_of_Seasonal_Explorers\prototypes\phase0_web

# Initialize Flutter Web project (one-time)
flutter create --platforms=web .

# Install dependencies
flutter pub get
```

Edit `web/index.html` (add before `</head>`):
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE&libraries=places,geometry" defer></script>
```

### Step 5: Run Prototypes

```powershell
# Prototype 1: Google Maps + Street View
flutter run -d chrome lib/prototype_1_google_maps.dart

# Prototype 2: Browser Geolocation
flutter run -d chrome lib/prototype_2_geolocation.dart
```

**Expected Results**:
- **Prototype 1**: Map with 3 quest markers (Bergamotto, Fichi, Nduja), click marker → Street View opens
- **Prototype 2**: Location permission prompt → position retrieved (500m+ accuracy on desktop = OK)

---

## 📊 Prototype Test Results (To Be Filled After Running)

### Prototype 1: Google Maps Integration
- [ ] Map loads in <5 seconds
- [ ] 3 quest markers visible
- [ ] Street View opens in <3 seconds
- [ ] Keyboard navigation works (arrow keys, +/-)
- [ ] Custom markers display correctly

**Performance**:
- Map load time: _____ seconds
- Street View load time: _____ seconds
- FPS during panning: _____ fps (target: 60fps)

**Issues Found**: _______________________________________

---

### Prototype 2: Browser Geolocation
- [ ] Permission prompt appears
- [ ] Location retrieved successfully
- [ ] Accuracy measured: _____ meters
- [ ] Graceful fallback message displays

**Geolocation Stats**:
- Latitude: _____________
- Longitude: _____________
- Accuracy: _____ meters (desktop typically 500m+)
- Time to retrieve: _____ ms

**Issues Found**: _______________________________________

---

## 🔧 Troubleshooting

### "flutter: command not found"
```powershell
# Add Flutter to PATH
$env:Path += ";C:\flutter\bin"
# Or add permanently via System Environment Variables
```

### "Google Maps JavaScript API error: InvalidKeyMapError"
→ Check API key restrictions in Google Cloud Console
→ Ensure localhost is whitelisted

### "getUserMedia is not a function"
→ Webcam requires HTTPS (or localhost)
→ Check browser permissions

### Map loads but no Street View
→ Enable "Street View Static API" in Google Cloud Console

---

## 📝 Current Documentation Status

| Document | Status | Notes |
|----------|--------|-------|
| `quickstart.md` | ✅ Updated | Flutter Web setup complete |
| `plan.md` | ✅ Updated | Technical context + project structure |
| `research.md` | ✅ Updated | Flutter Web decision rationale |
| `spec.md` | ✅ Updated | Google Maps as P1 feature |
| `data-model.md` | ✅ Updated | LocalStorage/IndexedDB schemas |
| `PHASE0_PROTOTYPES.md` | ✅ Complete | Full prototype specifications |
| `WEB_FIRST_CHANGES.md` | ✅ Complete | Platform pivot documentation |

---

## 🎯 Success Criteria for Phase 0

Before proceeding to Phase 1 (data models + full development):

1. ✅ **All documentation updated** (quickstart, plan, research, spec)
2. ⏳ **Prototype 1 validates**: Google Maps + Street View work in Flutter Web
3. ⏳ **Prototype 2 validates**: Browser Geolocation available (even with poor accuracy)
4. ⏳ **Prototype 3 validates**: Webcam capture works (to be created)
5. ⏳ **Prototype 4 validates**: LocalStorage handles 80 quests (~200KB) (to be created)
6. ⏳ **Prototype 5 validates**: Keyboard navigation WCAG 2.1 compliant (to be created)

**Current Status**: Documentation complete (1/1), Technical validation pending (0/5)

**Recommendation**: Install Flutter SDK → Run Prototypes 1-2 → Decide on proceeding to Phase 1

---

## 📞 Support

- **Flutter Web Docs**: https://docs.flutter.dev/platform-integration/web
- **Google Maps Flutter Web**: https://pub.dev/packages/google_maps_flutter_web
- **Geolocation**: https://pub.dev/packages/geolocator
- **Project Specs**: `specs/001-seasonal-quest-app/`
