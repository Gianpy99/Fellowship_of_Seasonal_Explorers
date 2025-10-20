import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Real GPS coordinates for Calabrian towns mentioned in seasonal products
/// Data sourced from OpenStreetMap / Google Maps
class CalabriaTowns {
  static const Map<String, LatLng> coordinates = {
    // Province of Reggio Calabria
    'Reggio Calabria': LatLng(38.1113, 15.6475),
    'Siderno': LatLng(38.2686, 16.2989),
    'Locri': LatLng(38.2357, 16.2625),
    'Polistena': LatLng(38.4014, 16.0778),
    'Bagnara Calabra': LatLng(38.2847, 15.8067),
    'Scilla': LatLng(38.2503, 15.7167),
    
    // Province of Vibo Valentia
    'Tropea': LatLng(38.6736, 15.8983),
    'Pizzo Calabro': LatLng(38.7344, 16.1681),
    
    // Province of Catanzaro
    'Catanzaro': LatLng(38.9094, 16.5877),
    'Lamezia Terme': LatLng(38.9660, 16.3100),
    'Soverato': LatLng(38.6872, 16.5511),
    'Serra San Bruno': LatLng(38.5761, 16.3289),
    
    // Province of Cosenza
    'Cosenza': LatLng(39.2986, 16.2517),
    'Rossano': LatLng(39.5767, 16.6358),
    'Belvedere Marittimo': LatLng(39.6211, 15.8631),
    'Scalea': LatLng(39.8136, 15.7908),
    'Amantea': LatLng(39.1392, 16.0744),
    'Diamante': LatLng(39.6825, 15.8222),
    'Sibari': LatLng(39.7458, 16.4939),
  };

  /// Get coordinates for a town name, with fallback to Reggio Calabria
  static LatLng getCoordinates(String? townName) {
    if (townName == null || townName.isEmpty) {
      return coordinates['Reggio Calabria']!; // Default fallback
    }
    
    return coordinates[townName] ?? coordinates['Reggio Calabria']!;
  }

  /// Get all unique town names
  static List<String> get allTowns => coordinates.keys.toList()..sort();

  /// Get town emoji based on location characteristics
  static String getTownEmoji(String townName) {
    // Coastal towns
    if (['Tropea', 'Pizzo Calabro', 'Scilla', 'Bagnara Calabra', 
         'Siderno', 'Locri', 'Belvedere Marittimo', 'Scalea', 
         'Amantea', 'Diamante', 'Sibari', 'Rossano'].contains(townName)) {
      return '🏖️';
    }
    
    // Mountain towns
    if (['Serra San Bruno', 'Cosenza'].contains(townName)) {
      return '⛰️';
    }
    
    // Capital cities
    if (['Reggio Calabria', 'Catanzaro', 'Lamezia Terme'].contains(townName)) {
      return '🏛️';
    }
    
    // Rural towns
    return '🏘️';
  }
}
