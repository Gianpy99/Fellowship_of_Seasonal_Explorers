import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/quest.dart';
import '../models/quest_location.dart';

/// Service to load and parse seasonal quest data from JSON
class QuestService {
  static List<Quest>? _cachedQuests;
  
  /// Load all quests from JSON file
  static Future<List<Quest>> loadQuests() async {
    // Return cached if available
    if (_cachedQuests != null) {
      return _cachedQuests!;
    }
    
    // Load JSON from assets
    final jsonString = await rootBundle.loadString('assets/seasonal_data.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final productsJson = jsonData['products'] as List;
    
    // Parse quests
    final quests = <Quest>[];
    for (final productJson in productsJson) {
      try {
        final quest = _parseQuest(productJson as Map<String, dynamic>);
        quests.add(quest);
      } catch (e) {
        print('Error parsing quest: ${productJson['id']} - $e');
      }
    }
    
    _cachedQuests = quests;
    return quests;
  }
  
  /// Parse a single quest from JSON
  static Quest _parseQuest(Map<String, dynamic> json) {
    // Parse months from strings to integers
    final harvestMonths = _parseMonths(json['harvest_months'] as List);
    final shelfMonths = _parseMonths(json['shelf_months'] as List);
    
    // Get location (default to Reggio Calabria market)
    final location = _getLocationForProduct(json['id'] as String);
    
    // Get stories (Calabria region)
    final storiesCalabria = json['stories']?['Calabria'] as List? ?? [];
    final storyIt = storiesCalabria
        .map((s) => (s as Map<String, dynamic>)['it'] as String)
        .toList();
    final storyEn = storiesCalabria
        .map((s) => (s as Map<String, dynamic>)['en'] as String)
        .toList();
    
    // Get educational text
    final educationalData = json['educational_text']?['Calabria'] as Map<String, dynamic>?;
    final educationalText = educationalData?['it'] as String? ?? json['notes_it'] as String;
    
    return Quest(
      id: json['id'] as String,
      nameIt: json['it'] as String,
      nameEn: json['en'] as String,
      category: _mapCategory(json['category'] as String),
      harvestMonths: harvestMonths,
      shelfMonths: shelfMonths,
      icon: json['icon'] as String,
      notesIt: json['notes_it'] as String,
      notesEn: json['notes_en'] as String,
      educationalText: educationalText,
      location: location,
      storyIt: storyIt,
      storyEn: storyEn,
      localTown: json['local_town'] as String?,
      // Cached images from JSON
      cachedIconBase64: json['cachedIconBase64'] as String?,
      cachedStoryBase64: (json['cachedStoryBase64'] as List?)
          ?.cast<String>()
          .toList(),
      cachedRecipeBase64: json['cachedRecipeBase64'] as String?,
    );
  }
  
  /// Parse month names to integers (1-12)
  static List<int> _parseMonths(List monthsList) {
    final monthMap = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
      'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
      'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    
    return monthsList
        .map((m) => monthMap[m as String] ?? 1)
        .toList();
  }
  
  /// Map category from Italian to English
  static String _mapCategory(String italianCategory) {
    final categoryMap = {
      'Frutti': 'fruit',
      'Verdure': 'vegetable',
      'Fiori': 'flower',
      'Prodotti Animali': 'animal_product',
    };
    return categoryMap[italianCategory] ?? 'fruit';
  }
  
  /// Get location for a product (distribute across Calabria locations)
  static QuestLocation _getLocationForProduct(String productId) {
    // Hash-based distribution for variety
    final hash = productId.hashCode;
    final locations = CalabriaLocations.all;
    return locations[hash.abs() % locations.length];
  }
  
  /// Filter quests by category
  static List<Quest> filterByCategory(List<Quest> quests, String category) {
    return quests.where((q) => q.category == category).toList();
  }
  
  /// Filter quests currently in season
  static List<Quest> filterInSeason(List<Quest> quests, [int? month]) {
    final currentMonth = month ?? DateTime.now().month;
    return quests.where((q) => q.isAvailableInMonth(currentMonth)).toList();
  }
  
  /// Filter quests currently in harvest
  static List<Quest> filterInHarvest(List<Quest> quests, [int? month]) {
    final currentMonth = month ?? DateTime.now().month;
    return quests.where((q) => q.isHarvestMonth(currentMonth)).toList();
  }
  
  /// Get quest statistics
  static Map<String, dynamic> getStatistics(List<Quest> quests) {
    final currentMonth = DateTime.now().month;
    return {
      'total': quests.length,
      'fruits': quests.where((q) => q.category == 'fruit').length,
      'vegetables': quests.where((q) => q.category == 'vegetable').length,
      'flowers': quests.where((q) => q.category == 'flower').length,
      'animal_products': quests.where((q) => q.category == 'animal_product').length,
      'in_season': quests.where((q) => q.isAvailableInMonth(currentMonth)).length,
      'in_harvest': quests.where((q) => q.isHarvestMonth(currentMonth)).length,
    };
  }
}
