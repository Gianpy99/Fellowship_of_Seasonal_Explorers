# Phase 0: Technical Prototypes - Flutter Web + Google Maps

**Date**: 2025-10-20  
**Framework**: ✅ Flutter Web (DECIDED)  
**Key Feature**: Google Maps Street View for virtual quest exploration

---

## Prototype 1: Google Maps Integration (PRIORITY)

### Goal
Verify that kids can explore quest locations using Google Maps Street View in a Flutter Web app.

### Required Setup
1. **Google Maps API Key**:
   ```bash
   # Create project at https://console.cloud.google.com/
   # Enable APIs:
   # - Maps JavaScript API
   # - Street View Static API (optional)
   # - Geolocation API
   
   # Get API key, restrict to your domain
   ```

2. **Flutter Dependencies**:
   ```yaml
   dependencies:
     google_maps_flutter: ^2.5.0
     google_maps_flutter_web: ^0.5.4
   ```

3. **Web Configuration** (`web/index.html`):
   ```html
   <head>
     <!-- Google Maps JavaScript API -->
     <script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY&libraries=places,geometry"></script>
   </head>
   ```

### Test Cases

#### TC1: Display Quest Location on Map
```dart
// lib/prototypes/google_maps_prototype.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsPrototype extends StatefulWidget {
  @override
  _GoogleMapsPrototypeState createState() => _GoogleMapsPrototypeState();
}

class _GoogleMapsPrototypeState extends State<GoogleMapsPrototype> {
  late GoogleMapController mapController;
  
  // Bergamotto quest in Calabria (example)
  final LatLng _questLocation = LatLng(38.1157, 15.6529); // Reggio Calabria
  
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prototype: Quest Location')),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _questLocation,
          zoom: 15.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId('quest'),
            position: _questLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: 'Bergamotto Quest',
              snippet: 'Esplora il mercato di Reggio Calabria',
            ),
          ),
        },
        mapType: MapType.hybrid, // Satellite view
      ),
    );
  }
}
```

**Expected Result**:
- Map loads in browser (Chrome/Firefox/Safari)
- Marker appears at quest location
- Keyboard navigation: Arrow keys pan, +/- zoom
- Performance: <2 seconds to load map tile

---

#### TC2: Street View Integration
```dart
// Check if Street View is available via JavaScript interop
import 'dart:html' as html;
import 'dart:js' as js;

class StreetViewPrototype extends StatelessWidget {
  final LatLng location = LatLng(38.1157, 15.6529);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prototype: Street View')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _openStreetView,
            child: Text('Esplora in Street View'),
          ),
          Expanded(
            child: HtmlElementView(
              viewType: 'street-view',
            ),
          ),
        ],
      ),
    );
  }
  
  void _openStreetView() {
    // Inject Street View panorama via JavaScript
    html.window.open(
      'https://www.google.com/maps/@${location.latitude},${location.longitude},3a,75y,90t/data=!3m7!1e1',
      'street_view',
      'width=800,height=600'
    );
  }
}
```

**Test**:
1. Click "Esplora in Street View"
2. New window opens with Street View at quest location
3. User can navigate with arrow keys
4. User can "walk" around the market/area

**Success Criteria**:
- Street View loads in <3 seconds
- Smooth keyboard navigation (arrow keys)
- Educational: Kids can see actual location without traveling

---

#### TC3: Custom Quest Markers
```dart
// Create custom marker icon for seasonal products
Future<BitmapDescriptor> _createCustomMarker(String productCategory) async {
  // Option 1: Use asset image
  return BitmapDescriptor.fromAssetImage(
    ImageConfiguration(size: Size(48, 48)),
    'assets/icons/${productCategory}_marker.png',
  );
  
  // Option 2: Use network image (from Python pipeline)
  // return BitmapDescriptor.fromBytes(imageBytes);
}

// Add to map:
markers: {
  Marker(
    markerId: MarkerId('bergamotto'),
    position: questLocation,
    icon: await _createCustomMarker('fruits'),
    onTap: () => _showQuestDetails(),
  ),
}
```

**Test**:
- Custom bergamotto icon appears on map (not default red pin)
- Click marker shows quest details popup
- Icon scales appropriately on zoom

---

## Prototype 2: Browser Geolocation API

### Goal
Test GPS accuracy on desktop/laptop and build graceful fallback.

### Test Implementation
```dart
// lib/prototypes/geolocation_prototype.dart
import 'package:geolocator/geolocator.dart';

class GeolocationPrototype extends StatefulWidget {
  @override
  _GeolocationPrototypeState createState() => _GeolocationPrototypeState();
}

class _GeolocationPrototypeState extends State<GeolocationPrototype> {
  Position? _currentPosition;
  String _status = 'Not tested';
  
  Future<void> _testGeolocation() async {
    setState(() => _status = 'Checking permissions...');
    
    // Check if location services enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = '❌ Location services disabled (expected on desktop)');
      return;
    }
    
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _status = '❌ Location permission denied');
        return;
      }
    }
    
    // Get current position
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      );
      
      setState(() {
        _currentPosition = position;
        _status = '✅ Location found!\n'
                 'Lat: ${position.latitude}\n'
                 'Lon: ${position.longitude}\n'
                 'Accuracy: ${position.accuracy}m';
      });
    } catch (e) {
      setState(() => _status = '❌ Error: $e\n(Fallback to Street View recommended)');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prototype: Geolocation')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testGeolocation,
              child: Text('Test GPS'),
            ),
            if (_currentPosition != null)
              ElevatedButton(
                onPressed: () => _checkProximity(LatLng(38.1157, 15.6529)),
                child: Text('Check if near quest (Calabria)'),
              ),
          ],
        ),
      ),
    );
  }
  
  void _checkProximity(LatLng questLocation) {
    if (_currentPosition == null) return;
    
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      questLocation.latitude,
      questLocation.longitude,
    );
    
    setState(() {
      if (distance <= 500) {
        _status += '\n\n✅ Within 500m of quest!';
      } else {
        _status += '\n\n❌ Too far (${distance.toInt()}m away)';
      }
    });
  }
}
```

**Expected Results on Desktop**:
- **Best Case**: WiFi-based geolocation (~100-500m accuracy)
- **Common Case**: "Location services disabled" or "GPS unavailable"
- **Fallback**: Show message "GPS non disponibile, usa Street View invece"

**Decision**: Make Street View primary, GPS optional enhancement

---

## Prototype 3: MediaDevices API (Webcam)

### Goal
Capture photos from webcam for quest completion.

### Test Implementation
```dart
// lib/prototypes/camera_prototype.dart
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:flutter_image_compress_web/flutter_image_compress_web.dart';
import 'dart:html' as html;

class CameraPrototype extends StatefulWidget {
  @override
  _CameraPrototypeState createState() => _CameraPrototypeState();
}

class _CameraPrototypeState extends State<CameraPrototype> {
  String? _imageDataUrl;
  
  Future<void> _capturePhoto() async {
    final picker = ImagePickerPlugin();
    
    // Request camera access (requires HTTPS!)
    final file = await picker.getImageFromSource(
      source: ImageSource.camera,
      options: ImagePickerOptions(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      ),
    );
    
    if (file != null) {
      final bytes = await file.readAsBytes();
      
      // Compress
      final compressed = await FlutterImageCompressWeb.compressImage(
        bytes,
        quality: 85,
      );
      
      // Convert to data URL for display
      final blob = html.Blob([compressed]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      setState(() => _imageDataUrl = url);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prototype: Webcam')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageDataUrl != null)
              Image.network(_imageDataUrl!, height: 300),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _capturePhoto,
              icon: Icon(Icons.camera_alt),
              label: Text('Cattura Foto'),
            ),
            SizedBox(height: 10),
            Text(
              'Nota: Richiede HTTPS (usa flutter run -d chrome --web-hostname localhost --web-port 8080)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Test Cases**:
1. Click "Cattura Foto" → Browser asks camera permission
2. Allow → Webcam preview appears
3. Take photo → Image compressed and displayed
4. Verify HTTPS requirement (will fail on http://)

**Expected Results**:
- Camera permission prompt appears (first time only)
- Photo captured in <1 second
- Compressed to <500KB
- Stored as base64 or Blob in LocalStorage

---

## Prototype 4: LocalStorage Performance

### Goal
Benchmark storing and loading 80 quests + user progress.

### Test Implementation
```dart
// lib/prototypes/storage_prototype.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StoragePrototype extends StatefulWidget {
  @override
  _StoragePrototypeState createState() => _StoragePrototypeState();
}

class _StoragePrototypeState extends State<StoragePrototype> {
  String _results = '';
  
  Future<void> _runBenchmark() async {
    final prefs = await SharedPreferences.getInstance();
    final stopwatch = Stopwatch()..start();
    
    // Simulate 80 quests
    final quests = List.generate(80, (i) => {
      'id': 'quest_$i',
      'title_it': 'Prodotto $i',
      'title_en': 'Product $i',
      'category': i % 4 == 0 ? 'fruits' : 'vegetables',
      'season': ['spring', 'summer', 'autumn', 'winter'][i % 4],
      'description_it': 'Descrizione lunga ' * 20, // ~400 chars
      'icon_path': 'assets/icons/product_$i.png',
    });
    
    final questsJson = json.encode({'quests': quests});
    print('Quests JSON size: ${questsJson.length} bytes (~${questsJson.length ~/ 1024}KB)');
    
    // WRITE test
    stopwatch.reset();
    await prefs.setString('quests_calabria', questsJson);
    final writeTime = stopwatch.elapsedMilliseconds;
    
    // READ test
    stopwatch.reset();
    final loaded = prefs.getString('quests_calabria');
    final readTime = stopwatch.elapsedMilliseconds;
    
    // PARSE test
    stopwatch.reset();
    final parsed = json.decode(loaded!);
    final parseTime = stopwatch.elapsedMilliseconds;
    
    setState(() {
      _results = '''
📊 Benchmark Results:
━━━━━━━━━━━━━━━━━━━━
Data Size: ${questsJson.length ~/ 1024}KB
Write Time: ${writeTime}ms
Read Time: ${readTime}ms
Parse Time: ${parseTime}ms
Total Startup: ${readTime + parseTime}ms

✅ Target: <200ms total
${readTime + parseTime < 200 ? '✅ PASS' : '❌ FAIL - Consider optimization'}
      ''';
    });
    
    stopwatch.stop();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prototype: Storage Performance')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_results, style: TextStyle(fontFamily: 'monospace')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runBenchmark,
              child: Text('Run Benchmark'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Success Criteria**:
- Total time <200ms for 80 quests (~200KB JSON)
- SharedPreferences works reliably on web
- No quota exceeded errors (LocalStorage limit ~5-10MB)

---

## Prototype 5: Keyboard Navigation

### Goal
Ensure app is fully keyboard accessible (WCAG 2.1 Level A).

### Test Implementation
```dart
// lib/prototypes/keyboard_prototype.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardPrototype extends StatefulWidget {
  @override
  _KeyboardPrototypeState createState() => _KeyboardPrototypeState();
}

class _KeyboardPrototypeState extends State<KeyboardPrototype> {
  int _selectedQuestIndex = 0;
  final List<String> _quests = [
    'Bergamotto (Inverno)',
    'Pomodoro (Estate)',
    'Zucca (Autunno)',
    'Asparagi (Primavera)',
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prototype: Keyboard Navigation')),
      body: Focus(
        autofocus: true,
        onKey: (node, event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                _selectedQuestIndex = (_selectedQuestIndex + 1) % _quests.length;
              });
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                _selectedQuestIndex = (_selectedQuestIndex - 1 + _quests.length) % _quests.length;
              });
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              _openQuest(_selectedQuestIndex);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Usa: ↑↓ per navigare, Enter per aprire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _quests.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedQuestIndex;
                  return Container(
                    color: isSelected ? Colors.blue.shade100 : null,
                    child: ListTile(
                      title: Text(
                        _quests[index],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () => _openQuest(index),
                      focusColor: Colors.blue.shade200,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _openQuest(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_quests[index]),
        content: Text('Quest aperto!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Chiudi (Esc)'),
          ),
        ],
      ),
    );
  }
}
```

**Test Cases**:
1. Tab navigation cycles through buttons
2. Arrow keys navigate quest list
3. Enter/Space activates selected quest
4. Escape closes modals
5. Focus indicator visible (blue highlight)

**Success Criteria**:
- All features accessible without mouse
- Visual focus indicators clear
- Keyboard shortcuts intuitive for kids learning to type

---

## Prototype Integration Plan

### Step 1: Create Flutter Web Project
```bash
# Create new Flutter web project
flutter create seasonal_quest_web --platforms=web
cd seasonal_quest_web

# Add dependencies to pubspec.yaml
flutter pub add google_maps_flutter google_maps_flutter_web
flutter pub add shared_preferences
flutter pub add image_picker_for_web flutter_image_compress_web
flutter pub add riverpod flutter_riverpod

# Run web server (HTTPS for camera)
flutter run -d chrome --web-port 8080
```

### Step 2: Prototype Dashboard
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'prototypes/google_maps_prototype.dart';
import 'prototypes/geolocation_prototype.dart';
import 'prototypes/camera_prototype.dart';
import 'prototypes/storage_prototype.dart';
import 'prototypes/keyboard_prototype.dart';

void main() {
  runApp(PrototypeDashboard());
}

class PrototypeDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phase 0 Prototypes',
      home: Scaffold(
        appBar: AppBar(title: Text('Seasonal Quest - Technical Prototypes')),
        body: ListView(
          children: [
            _prototypeCard(
              context,
              'Google Maps + Street View',
              'Test quest location markers and virtual exploration',
              GoogleMapsPrototype(),
            ),
            _prototypeCard(
              context,
              'Geolocation API',
              'Test GPS accuracy on desktop (expect degraded)',
              GeolocationPrototype(),
            ),
            _prototypeCard(
              context,
              'Webcam Capture',
              'Test MediaDevices API for photo capture',
              CameraPrototype(),
            ),
            _prototypeCard(
              context,
              'LocalStorage Performance',
              'Benchmark 80 quests storage and parsing',
              StoragePrototype(),
            ),
            _prototypeCard(
              context,
              'Keyboard Navigation',
              'Test WCAG-compliant keyboard controls',
              KeyboardPrototype(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _prototypeCard(BuildContext context, String title, String subtitle, Widget screen) {
    return Card(
      margin: EdgeInsets.all(16),
      child: ListTile(
        title: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        ),
      ),
    );
  }
}
```

---

## Success Metrics

| Prototype | Target | Measurement |
|-----------|--------|-------------|
| Google Maps | Loads in <2s | Time to first marker visible |
| Street View | Smooth navigation | 60fps arrow key response |
| Geolocation | Graceful fallback | Shows "GPS unavailable" on desktop |
| Webcam | Captures in <1s | Time from click to image |
| LocalStorage | Loads in <200ms | Parse + render 80 quests |
| Keyboard | 100% navigable | No feature requires mouse |

---

## Next Steps After Prototypes

1. ✅ **If all pass**: Proceed to Phase 1 (Data Layer)
2. ❌ **If Google Maps fails**: Fallback to static images + manual location entry
3. ❌ **If webcam fails**: Use file upload only (kids can take phone photos, upload later)
4. ❌ **If performance poor**: Reduce quest count or lazy-load images

**Estimated Time**: 2-3 days for all 5 prototypes
