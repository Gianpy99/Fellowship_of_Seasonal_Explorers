# Quickstart Guide: Seasonal Quest Web App Development

**Last Updated**: 2025-10-20  
**Target Developers**: Solo/family developers new to this codebase  
**Prerequisites**: Flutter SDK 3.16+, Dart 3.2+, Google Maps API key, VS Code or IntelliJ IDEA  
**Platform**: Web-first (desktop/laptop browsers) - Kids use family computer, not mobile devices yet

## Initial Setup (First Time)

### 1. Install Flutter with Web Support

```powershell
# Download and install Flutter SDK from https://flutter.dev
# Add Flutter to PATH
flutter --version  # Verify installation (should show 3.16+)
flutter doctor      # Check for missing dependencies

# Enable Flutter Web (one-time setup)
flutter channel stable
flutter upgrade
flutter config --enable-web
flutter doctor -v   # Verify "Chrome" is detected
```

### 2. Clone and Navigate

```powershell
cd C:\Development\Fellowship_of_Seasonal_Explorers
# Repository already initialized with git init --here
```

### 3. Create Flutter Web Project

```powershell
# Create new Flutter WEB project (--platforms=web flag critical!)
flutter create --platforms=web seasonal_quest_web
cd seasonal_quest_web

# Verify web support enabled
flutter devices  # Should show "Chrome (web)" in list
```

**Important**: The `--platforms=web` flag creates a web-only project. To add mobile support later (Phase 8):
```powershell
flutter create --platforms=ios,android .
```

### 4. Configure Google Maps API Key

#### 4.1 Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project: "Seasonal Quest Web"
3. Enable APIs:
   - **Maps JavaScript API** (for map display)
   - **Street View Static API** (for panoramas)
4. Create credentials → API Key
5. Restrict key (Security):
   - **Application restrictions**: HTTP referrers
     - Development: `http://localhost:*` and `http://127.0.0.1:*`
     - Production: `https://your-domain.web.app/*`
   - **API restrictions**: Select "Maps JavaScript API" and "Street View Static API"

#### 4.2 Add API Key to Project

Edit `web/index.html` (add before `</head>`):

```html
  <!-- Google Maps JavaScript API -->
  <script>
    window.GOOGLE_MAPS_API_KEY = "YOUR_API_KEY_HERE";
  </script>
  <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE&libraries=places" defer></script>
  
  <!-- Service Worker for PWA offline support -->
  <script>
    if ('serviceWorker' in navigator) {
      window.addEventListener('load', function () {
        navigator.serviceWorker.register('flutter_service_worker.js');
      });
    }
  </script>
</head>
```

**Security Best Practice**: For production, use environment variables:
```powershell
# Create .env file (add to .gitignore!)
echo "GOOGLE_MAPS_API_KEY=YOUR_API_KEY" > .env
```

### 5. Install Dependencies

Edit `pubspec.yaml`:

```yaml
name: seasonal_quest_web
description: Educational seasonal exploration web app for families
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_web_plugins:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # Google Maps Integration (CRITICAL for web)
  google_maps_flutter: ^2.5.0
  google_maps_flutter_web: ^0.5.4
  
  # Local Storage (Browser-based)
  shared_preferences: ^2.2.2
  shared_preferences_web: ^2.2.1
  
  # Browser APIs
  image_picker_for_web: ^3.0.1  # Webcam capture
  geolocator: ^10.1.0           # Browser Geolocation API
  geolocator_web: ^2.2.0
  
  # AI Integration (Optional - parental opt-in)
  google_generative_ai: ^0.2.0
  
  # Utilities
  intl: ^0.18.1        # Date/time formatting
  uuid: ^4.2.1         # Photo UUIDs
  path: ^1.8.3         # Path utilities
  http: ^1.1.0         # HTTP client for Gemini AI

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/icons/
    - assets/images/story_scenes/
    - assets/images/recipes/
    - assets/badges/
    - assets/characters/
    - assets/data/
```

Install packages:

```powershell
flutter pub get
```

### 5. Configure Environment Variables

Create `.env` file in `seasonal_quest_app/` root:

```env
GEMINI_API_KEY=your_actual_api_key_here
```

Add to `.gitignore`:

```gitignore
# Environment variables
.env
```

### 6. Copy Existing Assets

```powershell
# Copy pre-generated images from Python pipeline
mkdir seasonal_quest_web\web\assets\images
xcopy /E /I ..\images_icons seasonal_quest_web\web\assets\images\icons
xcopy /E /I ..\images_story_scenes_random seasonal_quest_web\web\assets\images\story_scenes
xcopy /E /I ..\images_recipes seasonal_quest_web\web\assets\images\recipes

# Create quest data from existing JSON
# (See "Data Transformation" section below)
```

## Project Structure Overview (Flutter Web)

```
seasonal_quest_web/
├── lib/
│   ├── main.dart              # App entry point - START HERE
│   ├── models/                # Data classes (Quest, Badge, VirtualExplorationSession)
│   ├── services/              # Business logic (maps, storage, webcam, AI)
│   │   ├── google_maps_service.dart   # Google Maps + Street View
│   │   ├── storage_service.dart       # LocalStorage/IndexedDB wrapper
│   │   ├── webcam_service.dart        # MediaDevices API capture
│   │   ├── geolocation_service.dart   # Browser Geolocation (optional)
│   │   └── ai_service.dart            # Gemini AI (parental opt-in)
│   ├── screens/               # Full-page UI (HomeScreen with Maps, QuestDetailScreen)
│   ├── widgets/               # Reusable components (QuestCard, BadgeWidget, StreetViewEmbed)
│   ├── providers/             # Riverpod state management
│   ├── utils/                 # Constants, helpers, keyboard nav utilities
│   └── data/                  # Static JSON files (quest packs)
├── web/                       # Web-specific files
│   ├── index.html             # Google Maps API key injection (EDIT THIS!)
│   ├── manifest.json          # PWA configuration
│   ├── favicon.png            # App icon
│   └── assets/                # Bundled assets (images, JSON)
├── test/                      # Unit, widget tests
└── integration_test/          # Browser automation tests
└── pubspec.yaml               # Dependencies configuration
```

## Development Workflow (Flutter Web)

### Step 1: Data Transformation (One-Time)

Transform existing seasonal database to Flutter-compatible format:

```python
# Run this Python script to generate web/assets/data/quests_calabria.json
import json

with open('seasonal_db_complete_story_cards__WITH_3x_stories_20250813_101620.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

quests = []
for product in data['products']:
    # Derive season from harvest_months
    harvest = product.get('harvest_months', [])
    season = 'autumn'  # Default, refine based on months
    if any(m in harvest for m in ['Mar', 'Apr', 'May']):
        season = 'spring'
    elif any(m in harvest for m in ['Jun', 'Jul', 'Aug']):
        season = 'summer'
    elif any(m in harvest for m in ['Sep', 'Oct', 'Nov']):
        season = 'autumn'
    elif any(m in harvest for m in ['Dec', 'Jan', 'Feb']):
        season = 'winter'
    
    quest = {
        'id': product['id'],
        'title_it': product['it'],
        'title_en': product['en'],
        'description_it': product['stories']['Calabria'][0]['it'],
        'description_en': product['stories']['Calabria'][0]['en'],
        'category': product['category'].lower(),
        'season': season,
        'region': 'calabria',
        'difficulty': 'medium',
        'estimated_minutes': 15,
        'educational_content_it': product['educational_text']['Calabria']['it'],
        'educational_content_en': product['educational_text']['Calabria']['en'],
        'icon_path': 'assets/images/icons/${product["icon"]}',
        'story_image_path': f'assets/images/story_scenes/{product["en"].lower().replace(" ", "_")}_story1.png',
        'character_name': 'Lina',
        'requires_location': False,  # Optional on web (GPS unreliable on desktop)
        'location': {
            'name': 'Reggio Calabria Farmers Market',  # Example, customize per product
            'lat': 38.1095,
            'lng': 15.6470,
            'street_view_pano_id': None  # Auto-detect or set manually
        }
    }
    quests.append(quest)

with open('seasonal_quest_web/web/assets/data/quests_calabria.json', 'w', encoding='utf-8') as out:
    json.dump({'quests': quests}, out, indent=2, ensure_ascii=False)

print(f"Generated {len(quests)} quests for Calabria region")
```

### Step 2: Run the App in Browser (Development)

```powershell
cd seasonal_quest_web

# Run in Chrome (default, best for debugging)
flutter run -d chrome

# Or run on web server (test in multiple browsers)
flutter run -d web-server --web-port=8080
# Then open http://localhost:8080 in any browser

# Production build (optimized)
flutter build web --release --web-renderer canvaskit
# Output: build/web/ directory ready for deployment
```

**Browser DevTools**:
- **Chrome DevTools**: F12 → Console (see Dart print statements)
- **Network Tab**: Monitor Google Maps API calls
- **Application Tab**: Inspect LocalStorage/IndexedDB data

### Step 3: Hot Reload During Development

While app is running:
- **Hot Reload**: Press `r` in terminal or save file in IDE (keeps state, <3s refresh)
- **Hot Restart**: Press `R` in terminal (resets state, clears LocalStorage cache)
- **Quit**: Press `q` in terminal

**Note**: Changes to `web/index.html` require full restart (stop + `flutter run` again)

### Step 4: Test Google Maps Integration

Before writing code, verify API key works:

```powershell
# Run app and check browser console
flutter run -d chrome
# In Chrome DevTools Console, look for:
#   ✅ "Google Maps JavaScript API loaded"
#   ❌ "Google Maps JavaScript API error: InvalidKeyMapError" (fix API key)
```

Test Street View manually:
1. Run app
2. Open Chrome DevTools → Console
3. Type: `new google.maps.StreetViewPanorama(...)` should exist (no errors)

### Step 5: Common Development Tasks

#### Add a New Screen

```dart
// lib/screens/new_screen.dart
import 'package:flutter/material.dart';

class NewScreen extends StatelessWidget {
  const NewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Screen')),
      body: Center(child: Text('Content here')),
    );
  }
}
```

#### Create a New Service

```dart
// lib/services/example_service.dart
class ExampleService {
  Future<void> doSomething() async {
    // Business logic here
  }
}
```

#### Add a Riverpod Provider

```dart
// lib/providers/example_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final exampleProvider = Provider<String>((ref) => 'Hello');
```

## Testing

### Run All Tests

```powershell
flutter test
```

### Run Specific Test File

```powershell
flutter test test/unit_test/quest_service_test.dart
```

### Run Widget Tests

```powershell
flutter test --plain-name "QuestCard displays correctly"
```

### Run Integration Tests

```powershell
flutter test integration_test/quest_completion_test.dart
```

## Building for Release

### Android APK

```powershell
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)

```powershell
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (requires macOS + Xcode)

```powershell
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode to archive
```

## Debugging Tips

### Check Device Logs

```powershell
flutter logs
```

### Debug Performance

```powershell
# Open Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Common Issues

**Issue**: "Unable to locate package sqflite"  
**Solution**: Run `flutter pub get` and ensure pubspec.yaml syntax is correct

**Issue**: GPS not working in emulator  
**Solution**: Use Android Studio's location simulator or test on physical device

**Issue**: Camera not working  
**Solution**: Check permissions in AndroidManifest.xml and Info.plist

**Issue**: Images not loading  
**Solution**: Verify paths in pubspec.yaml `assets:` section match actual file locations

## Database Inspection

### View SQLite Database (Development)

```powershell
# Pull database from device
adb pull /data/data/com.example.seasonal_quest_app/databases/seasonal_quests.db

# Open in DB Browser for SQLite
# Download from: https://sqlitebrowser.org/
```

### Reset Database (Testing)

```dart
// In app code (dev only):
final dbPath = await getDatabasesPath();
await deleteDatabase(join(dbPath, 'seasonal_quests.db'));
```

## Performance Profiling

### Measure App Startup Time

```powershell
flutter run --profile --trace-startup
# Results in build/start_up_info.json
```

### Check Widget Rebuild Performance

```dart
// Add to main.dart in debug mode
debugProfileBuildsEnabled = true;
```

## Continuous Development

### Daily Workflow

1. Pull latest changes: `git pull`
2. Update dependencies: `flutter pub get`
3. Run tests: `flutter test`
4. Start dev server: `flutter run`
5. Make changes (hot reload automatically)
6. Commit when ready: `git commit -m "message"`

### Feature Development Cycle

1. Create feature branch: `git checkout -b feature/badge-animations`
2. Implement in small increments (test frequently)
3. Write tests for new functionality
4. Manual test on device with children (observe UX)
5. Merge to main when complete

## Resources

### Flutter Documentation
- **Official Docs**: https://docs.flutter.dev
- **Widget Catalog**: https://docs.flutter.dev/ui/widgets
- **Riverpod Guide**: https://riverpod.dev

### Project-Specific Resources
- **Spec**: `specs/001-seasonal-quest-app/spec.md`
- **Data Model**: `specs/001-seasonal-quest-app/data-model.md`
- **Research**: `specs/001-seasonal-quest-app/research.md`
- **Gemini API**: `specs/001-seasonal-quest-app/contracts/gemini-ai.md`

### Community
- **Flutter Discord**: https://discord.gg/flutter
- **Stack Overflow**: Tag questions with `flutter` and `dart`

## Next Steps After Quickstart

1. ✅ Environment set up
2. ⏭️ Implement core data models (`lib/models/quest.dart`, etc.)
3. ⏭️ Set up SQLite database service (`lib/services/storage_service.dart`)
4. ⏭️ Build first screen: HomeScreen with quest list
5. ⏭️ Implement GPS check-in flow
6. ⏭️ Add camera integration for photo capture
7. ⏭️ Build badge system
8. ⏭️ Integrate Gemini AI recommendations
9. ⏭️ Test with family (children ages 5-12)
10. ⏭️ Refine UX based on feedback

**Time Estimate for MVP (P1 features)**: 4-6 weeks solo development, working evenings/weekends

---

**Questions?** Review the specification docs in `specs/001-seasonal-quest-app/` or refer to existing Python codebase patterns in `generate_all_with_estimation_seed_quality_parallel.py` for asset generation workflows.
