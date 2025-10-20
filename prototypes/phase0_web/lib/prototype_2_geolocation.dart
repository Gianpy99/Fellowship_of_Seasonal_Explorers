import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Prototype 2: Browser Geolocation API
/// 
/// Tests:
/// - TC1: Request location permission
/// - TC2: Get current position (expect low accuracy on desktop ~500m)
/// - TC3: Graceful degradation when GPS unavailable
///
/// Success Criteria:
/// - Permission prompt appears in browser
/// - Location retrieved (any accuracy acceptable)
/// - App works without GPS (fallback to virtual exploration)

void main() {
  runApp(MaterialApp(
    title: 'Prototype 2: Geolocation',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: GeolocationPrototype(),
  ));
}

class GeolocationPrototype extends StatefulWidget {
  @override
  _GeolocationPrototypeState createState() => _GeolocationPrototypeState();
}

class _GeolocationPrototypeState extends State<GeolocationPrototype> {
  Position? _currentPosition;
  String _statusMessage = 'Not requested yet';
  bool _isLoading = false;
  LocationPermission? _permission;
  double? _accuracy;
  
  Future<void> _checkPermission() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking permission...';
    });
    
    try {
      _permission = await Geolocator.checkPermission();
      setState(() {
        _statusMessage = 'Permission status: ${_permission.toString()}';
        _isLoading = false;
      });
      print('[Prototype 2] Permission: $_permission');
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking permission: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _requestLocation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting location...';
    });
    
    try {
      // Check permission first
      _permission = await Geolocator.checkPermission();
      
      if (_permission == LocationPermission.denied) {
        _permission = await Geolocator.requestPermission();
        if (_permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = '❌ Location permission denied';
            _isLoading = false;
          });
          return;
        }
      }
      
      if (_permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = '❌ Location permission permanently denied';
          _isLoading = false;
        });
        return;
      }
      
      // Get position with 5 second timeout
      final startTime = DateTime.now();
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // ~100m
        timeLimit: Duration(seconds: 5),
      );
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      
      _accuracy = _currentPosition!.accuracy;
      
      setState(() {
        _statusMessage = '✅ Location retrieved in ${elapsed}ms';
        _isLoading = false;
      });
      
      print('[Prototype 2] Position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      print('[Prototype 2] Accuracy: ${_accuracy}m');
      
      // Check if accuracy is acceptable for quest proximity (100m tolerance)
      if (_accuracy! <= 150) {
        print('[Prototype 2] ✅ Accuracy good enough for quest check-in');
      } else {
        print('[Prototype 2] ⚠️ Accuracy poor (expected on desktop). Use virtual exploration instead.');
      }
      
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e (expected on desktop without GPS)';
        _isLoading = false;
      });
      print('[Prototype 2] Error: $e');
    }
  }
  
  Widget _buildLocationCard() {
    if (_currentPosition == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No location data yet'),
        ),
      );
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 Current Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildLocationRow('Latitude', '${_currentPosition!.latitude.toStringAsFixed(6)}°'),
            _buildLocationRow('Longitude', '${_currentPosition!.longitude.toStringAsFixed(6)}°'),
            _buildLocationRow('Accuracy', '${_accuracy!.toStringAsFixed(0)}m'),
            _buildLocationRow('Timestamp', '${_currentPosition!.timestamp}'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accuracy! <= 150 ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _accuracy! <= 150 ? Icons.check_circle : Icons.warning,
                    color: _accuracy! <= 150 ? Colors.green : Colors.orange,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _accuracy! <= 150
                          ? 'Accuracy good enough for GPS check-in'
                          : 'Poor accuracy (expected on desktop). Use virtual exploration instead.',
                      style: TextStyle(
                        color: _accuracy! <= 150 ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prototype 2: Browser Geolocation'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🧭 Test Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text('1. Click "Check Permission" to see current status'),
                  Text('2. Click "Request Location" to trigger browser permission'),
                  Text('3. Accept permission prompt'),
                  Text('4. Check accuracy (expect 500m+ on desktop)'),
                  SizedBox(height: 12),
                  Text(
                    '✅ Success: Permission works, location retrieved (any accuracy OK)',
                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '⚠️ Expected: Poor accuracy on desktop/laptop (use virtual exploration)',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkPermission,
                    icon: Icon(Icons.shield),
                    label: Text('Check Permission'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _requestLocation,
                    icon: Icon(Icons.location_on),
                    label: Text('Request Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Status Message
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _statusMessage.startsWith('✅')
                          ? Icons.check_circle
                          : _statusMessage.startsWith('❌')
                              ? Icons.error
                              : Icons.info,
                      color: _statusMessage.startsWith('✅')
                          ? Colors.green
                          : _statusMessage.startsWith('❌')
                              ? Colors.red
                              : Colors.grey,
                    ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Location Data
            _buildLocationCard(),
            
            SizedBox(height: 24),
            
            // Fallback Message
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.streetview, color: Colors.green),
                      SizedBox(width: 12),
                      Text(
                        'Graceful Degradation',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'If GPS unavailable or inaccurate, users can still complete quests via:',
                  ),
                  SizedBox(height: 8),
                  Text('✅ Virtual exploration (Google Maps Street View)'),
                  Text('✅ Webcam photo verification (bring product home)'),
                  Text('✅ Manual location entry (future feature)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
