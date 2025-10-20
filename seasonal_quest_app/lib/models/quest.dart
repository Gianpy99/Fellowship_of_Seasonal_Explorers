import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'quest_location.dart';
import '../data/calabria_towns.dart';

/// Represents a seasonal quest (seasonal product to discover)
class Quest {
  final String id;
  final String nameIt;
  final String nameEn;
  final String category; // 'fruit', 'vegetable', 'flower', 'animal_product'
  final List<int> harvestMonths; // 1-12
  final List<int> shelfMonths; // 1-12
  final String icon;
  final String notesIt;
  final String notesEn;
  final String educationalText;
  final QuestLocation location;
  final List<String> storyIt;
  final List<String> storyEn;
  final String? imageIconPath;
  final String? imageStoryPath;
  final String? imageRecipePath;
  final String? localTown; // Città calabrese specifica del prodotto
  
  // AI-generated images (stored in assets/images/generated/)
  final String? generatedIconPath;
  final List<String>? generatedStoryPaths; // One per story
  final String? generatedRecipePath;
  
  // Custom AI prompts (saved when user modifies them)
  final String? customIconPrompt;
  final String? customStoryPrompt;
  final String? customRecipePrompt;
  
  // Cached images as base64 (stored in seasonal_data.json)
  final String? cachedIconBase64; // Icon image
  final List<String>? cachedStoryBase64; // Story images (one per story)
  final String? cachedRecipeBase64; // Recipe image
  
  Quest({
    required this.id,
    required this.nameIt,
    required this.nameEn,
    required this.category,
    required this.harvestMonths,
    required this.shelfMonths,
    required this.icon,
    required this.notesIt,
    required this.notesEn,
    required this.educationalText,
    required this.location,
    required this.storyIt,
    required this.storyEn,
    this.imageIconPath,
    this.imageStoryPath,
    this.imageRecipePath,
    this.localTown,
    this.generatedIconPath,
    this.generatedStoryPaths,
    this.generatedRecipePath,
    this.customIconPrompt,
    this.customStoryPrompt,
    this.customRecipePrompt,
    this.cachedIconBase64,
    this.cachedStoryBase64,
    this.cachedRecipeBase64,
  });
  
  /// Get real GPS coordinates for this quest's town
  LatLng get coordinates {
    return CalabriaTowns.getCoordinates(localTown);
  }
  
  /// Get town-specific emoji
  String get townEmoji {
    return localTown != null 
        ? CalabriaTowns.getTownEmoji(localTown!) 
        : location.typeEmoji;
  }
  
  /// Check if quest is available in current month
  bool isAvailableInMonth(int month) {
    return shelfMonths.contains(month);
  }
  
  /// Check if it's harvest season
  bool isHarvestMonth(int month) {
    return harvestMonths.contains(month);
  }
  
  /// Get category emoji
  String get categoryEmoji {
    switch (category) {
      case 'fruit':
        return '🍎';
      case 'vegetable':
        return '🥕';
      case 'flower':
        return '🌸';
      case 'animal_product':
        return '🥛';
      default:
        return '🌿';
    }
  }
  
  /// Get season name based on current availability
  String getSeasonName() {
    final now = DateTime.now().month;
    if (shelfMonths.contains(now)) {
      if (harvestMonths.contains(now)) {
        return 'In harvest!';
      }
      return 'In season';
    }
    return 'Out of season';
  }
  
  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] as String,
      nameIt: json['it'] as String,
      nameEn: json['en'] as String,
      category: json['category'] as String,
      harvestMonths: (json['harvest_months'] as List).cast<int>(),
      shelfMonths: (json['shelf_months'] as List).cast<int>(),
      icon: json['icon'] as String,
      notesIt: json['notes_it'] as String,
      notesEn: json['notes_en'] as String,
      educationalText: json['educational_text'] as String,
      location: QuestLocation.fromJson(json['location'] as Map<String, dynamic>),
      storyIt: (json['stories']['Calabria']['it'] as List).cast<String>(),
      storyEn: (json['stories']['Calabria']['en'] as List).cast<String>(),
      imageIconPath: json['image_icon_path'] as String?,
      imageStoryPath: json['image_story_path'] as String?,
      imageRecipePath: json['image_recipe_path'] as String?,
      localTown: json['local_town'] as String?,
      generatedIconPath: json['generated_icon_path'] as String?,
      generatedStoryPaths: json['generated_story_paths'] != null
          ? (json['generated_story_paths'] as List).cast<String>()
          : null,
      generatedRecipePath: json['generated_recipe_path'] as String?,
      customIconPrompt: json['custom_icon_prompt'] as String?,
      customStoryPrompt: json['custom_story_prompt'] as String?,
      customRecipePrompt: json['custom_recipe_prompt'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'it': nameIt,
      'en': nameEn,
      'category': category,
      'harvest_months': harvestMonths,
      'shelf_months': shelfMonths,
      'icon': icon,
      'notes_it': notesIt,
      'notes_en': notesEn,
      'educational_text': educationalText,
      'location': location.toJson(),
      'stories': {
        'Calabria': {
          'it': storyIt,
          'en': storyEn,
        }
      },
      'image_icon_path': imageIconPath,
      'image_story_path': imageStoryPath,
      'image_recipe_path': imageRecipePath,
      'local_town': localTown,
    };
  }
}
