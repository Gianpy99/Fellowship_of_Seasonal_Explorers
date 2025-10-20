import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Geographic location for a quest (market, farm, etc.)
class QuestLocation {
  final String id;
  final String name;
  final String description;
  final LatLng coordinates;
  final String type; // 'market', 'farm', 'orchard', 'forest'
  final String address;
  final bool hasStreetView;
  
  QuestLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.coordinates,
    required this.type,
    required this.address,
    this.hasStreetView = true,
  });
  
  /// Get Street View URL
  String getStreetViewUrl() {
    final lat = coordinates.latitude;
    final lng = coordinates.longitude;
    return 'https://www.google.com/maps/@$lat,$lng,3a,75y,90t/data=!3m7!1e1';
  }
  
  /// Get Google Maps search URL
  String getGoogleMapsUrl() {
    final lat = coordinates.latitude;
    final lng = coordinates.longitude;
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }
  
  /// Get location type emoji
  String get typeEmoji {
    switch (type) {
      case 'market':
        return '🏪';
      case 'farm':
        return '🚜';
      case 'orchard':
        return '🌳';
      case 'forest':
        return '🌲';
      default:
        return '📍';
    }
  }
  
  factory QuestLocation.fromJson(Map<String, dynamic> json) {
    return QuestLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      coordinates: LatLng(
        json['coordinates']['lat'] as double,
        json['coordinates']['lng'] as double,
      ),
      type: json['type'] as String,
      address: json['address'] as String,
      hasStreetView: json['has_street_view'] as bool? ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coordinates': {
        'lat': coordinates.latitude,
        'lng': coordinates.longitude,
      },
      'type': type,
      'address': address,
      'has_street_view': hasStreetView,
    };
  }
}

/// Predefined locations in Calabria for quests
class CalabriaLocations {
  static final mercatoReggioCalabria = QuestLocation(
    id: 'mercato_reggio_calabria',
    name: 'Mercato Comunale Reggio Calabria',
    description: 'Esplora il mercato di Reggio Calabria',
    coordinates: LatLng(38.10843, 15.64294),
    type: 'market',
    address: 'Piazza del Popolo, Reggio Calabria',
  );
  
  static final mercatoCosenza = QuestLocation(
    id: 'mercato_cosenza',
    name: 'Mercato Coperto Cosenza',
    description: 'Visita il mercato coperto di Cosenza',
    coordinates: LatLng(39.29815, 16.25279),
    type: 'market',
    address: 'Piazza Luigi Fera, Cosenza',
  );
  
  static final centroSpilinga = QuestLocation(
    id: 'centro_spilinga',
    name: 'Centro Storico Spilinga',
    description: 'Scopri il centro storico di Spilinga',
    coordinates: LatLng(38.60833, 15.91167),
    type: 'market',
    address: 'Piazza Roma, Spilinga',
  );
  
  static List<QuestLocation> get all => [
    mercatoReggioCalabria,
    mercatoCosenza,
    centroSpilinga,
  ];
}
