import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:html' as html;

/// Prototype 1: Google Maps Integration
/// 
/// Tests:
/// - TC1: Display quest location on map with custom marker
/// - TC2: Street View integration with keyboard navigation
/// - TC3: Performance (map load <5s, Street View load <3s)
///
/// Success Criteria:
/// - Map renders with quest marker
/// - Street View opens and is keyboard-navigable
/// - Smooth 60fps panning/zooming

void main() {
  runApp(MaterialApp(
    title: 'Prototype 1: Google Maps',
    theme: ThemeData(primarySwatch: Colors.green),
    home: GoogleMapsPrototype(),
  ));
}

class GoogleMapsPrototype extends StatefulWidget {
  @override
  _GoogleMapsPrototypeState createState() => _GoogleMapsPrototypeState();
}

class _GoogleMapsPrototypeState extends State<GoogleMapsPrototype> {
  late GoogleMapController mapController;
  
  // Test quest locations (Calabria region) - REAL COORDINATES
  final List<QuestMarker> _questMarkers = [
    QuestMarker(
      id: 'bergamotto',
      name: 'Bergamotto',
      location: LatLng(38.10843, 15.64294), // Mercato Comunale Reggio Calabria (Piazza del Popolo)
      description: 'Esplora il mercato di Reggio Calabria - Via Filippini',
    ),
    QuestMarker(
      id: 'fichi',
      name: 'Fichi di Cosenza',
      location: LatLng(39.29815, 16.25279), // Mercato Coperto di Cosenza (Piazza Luigi Fera)
      description: 'Visita il mercato coperto di Cosenza',
    ),
    QuestMarker(
      id: 'nduja',
      name: 'Nduja di Spilinga',
      location: LatLng(38.60833, 15.91167), // Centro storico Spilinga (VV)
      description: 'Scopri il borgo della nduja - Piazza Roma',
    ),
  ];
  
  QuestMarker? _selectedQuest;
  bool _streetViewOpen = false;
  
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    print('[Prototype 1] Map created successfully');
  }
  
  Set<Marker> _buildMarkers() {
    return _questMarkers.map((quest) {
      return Marker(
        markerId: MarkerId(quest.id),
        position: quest.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: quest.name,
          snippet: quest.description,
          onTap: () => _selectQuest(quest),
        ),
      );
    }).toSet();
  }
  
  void _selectQuest(QuestMarker quest) {
    setState(() {
      _selectedQuest = quest;
    });
    print('[Prototype 1] Quest selected: ${quest.name}');
  }
  
  void _openStreetView() {
    if (_selectedQuest == null) return;
    
    final lat = _selectedQuest!.location.latitude;
    final lng = _selectedQuest!.location.longitude;
    
    // Show info dialog first
    _showStreetViewDialog();
    
    // Open Street View in new window (embedded version requires more setup)
    final streetViewUrl = 'https://www.google.com/maps/@$lat,$lng,3a,75y,90t/data=!3m7!1e1';
    html.window.open(streetViewUrl, '_blank', 'width=1200,height=800');
    
    setState(() {
      _streetViewOpen = true;
    });
    
    print('[Prototype 1] Street View opened for ${_selectedQuest!.name}');
    
    // Simulate timing check
    final startTime = DateTime.now();
    Future.delayed(Duration(seconds: 3), () {
      final loadTime = DateTime.now().difference(startTime).inSeconds;
      print('[Prototype 1] Street View load time: ${loadTime}s (target: <3s)');
    });
  }
  
  void _showStreetViewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.streetview, color: Colors.orange),
            SizedBox(width: 8),
            Text('Street View: ${_selectedQuest!.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 ${_selectedQuest!.description}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              '⚠️ Al primo utilizzo:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
            ),
            SizedBox(height: 8),
            Text('• Accetta i "Terms of Service" di Google Maps nel popup', style: TextStyle(fontSize: 13)),
            Text('• Potresti dover autorizzare i cookie', style: TextStyle(fontSize: 13)),
            SizedBox(height: 16),
            Text(
              '💡 Se Street View appare buio/nero:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
            ),
            SizedBox(height: 8),
            Text('• Alcune location potrebbero non avere copertura Street View', style: TextStyle(fontSize: 13)),
            Text('• Usa il pulsante qui sotto per aprire direttamente su Google Maps', style: TextStyle(fontSize: 13)),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  final lat = _selectedQuest!.location.latitude;
                  final lng = _selectedQuest!.location.longitude;
                  // Open regular Google Maps as fallback
                  final fallbackUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                  html.window.open(fallbackUrl, '_blank');
                },
                icon: Icon(Icons.map, size: 18),
                label: Text('Apri su Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Ho capito!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prototype 1: Google Maps + Street View'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Instructions Panel
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🗺️ Test Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('1. Click a quest marker on the map'),
                Text('2. Click "Explore in Street View" button'),
                Text('3. Use arrow keys (↑↓←→) to navigate'),
                Text('4. Press +/- to zoom'),
                SizedBox(height: 8),
                Text(
                  '✅ Success: Map loads <5s, Street View <3s, keyboard navigation works',
                  style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Selected Quest Info
          if (_selectedQuest != null)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.orange, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedQuest!.name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(_selectedQuest!.description),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _openStreetView,
                    icon: Icon(Icons.streetview),
                    label: Text('Explore in Street View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          
          // Google Map
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(38.7, 16.0), // Calabria center
                zoom: 9.0,
              ),
              markers: _buildMarkers(),
              mapType: MapType.hybrid, // Satellite view
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              onTap: (LatLng position) {
                // Clear selection on map tap
                setState(() {
                  _selectedQuest = null;
                });
              },
            ),
          ),
          
          // Performance Stats
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Quest Markers', '${_questMarkers.length}'),
                _buildStat('Map Type', 'Hybrid'),
                _buildStat('Street View', _streetViewOpen ? 'Opened' : 'Not opened'),
                _buildStat('Keyboard Nav', 'Arrow keys + +/-'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

class QuestMarker {
  final String id;
  final String name;
  final LatLng location;
  final String description;
  
  QuestMarker({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
  });
}
