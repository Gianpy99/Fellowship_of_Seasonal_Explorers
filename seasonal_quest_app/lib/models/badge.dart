/// Achievement badge earned by completing quests
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeType type;
  final int requirementCount; // Number of quests needed
  final bool isUnlocked;
  final DateTime? unlockedAt;
  
  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.requirementCount,
    this.isUnlocked = false,
    this.unlockedAt,
  });
  
  /// Copy with unlocked status
  Badge copyWithUnlocked(DateTime unlockedAt) {
    return Badge(
      id: id,
      name: name,
      description: description,
      icon: icon,
      type: type,
      requirementCount: requirementCount,
      isUnlocked: true,
      unlockedAt: unlockedAt,
    );
  }
  
  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: BadgeType.values.byName(json['type'] as String),
      requirementCount: json['requirement_count'] as int,
      isUnlocked: json['is_unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null 
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type.name,
      'requirement_count': requirementCount,
      'is_unlocked': isUnlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }
}

enum BadgeType {
  seasonal, // Complete all quests in a season
  explorer, // Visit different locations
  collector, // Complete quests of specific category
  master, // Complete all quests
}

/// Predefined badges
class Badges {
  static final springExplorer = Badge(
    id: 'spring_explorer',
    name: 'Spring Explorer',
    description: 'Complete 5 spring quests',
    icon: '🌸',
    type: BadgeType.seasonal,
    requirementCount: 5,
  );
  
  static final summerExplorer = Badge(
    id: 'summer_explorer',
    name: 'Summer Explorer',
    description: 'Complete 5 summer quests',
    icon: '☀️',
    type: BadgeType.seasonal,
    requirementCount: 5,
  );
  
  static final autumnExplorer = Badge(
    id: 'autumn_explorer',
    name: 'Autumn Explorer',
    description: 'Complete 5 autumn quests',
    icon: '🍂',
    type: BadgeType.seasonal,
    requirementCount: 5,
  );
  
  static final winterExplorer = Badge(
    id: 'winter_explorer',
    name: 'Winter Explorer',
    description: 'Complete 5 winter quests',
    icon: '❄️',
    type: BadgeType.seasonal,
    requirementCount: 5,
  );
  
  static final fruitCollector = Badge(
    id: 'fruit_collector',
    name: 'Fruit Collector',
    description: 'Complete all fruit quests',
    icon: '🍎',
    type: BadgeType.collector,
    requirementCount: 10,
  );
  
  static final vegetableCollector = Badge(
    id: 'vegetable_collector',
    name: 'Vegetable Collector',
    description: 'Complete all vegetable quests',
    icon: '🥕',
    type: BadgeType.collector,
    requirementCount: 10,
  );
  
  static final marketExplorer = Badge(
    id: 'market_explorer',
    name: 'Market Explorer',
    description: 'Visit 3 different markets',
    icon: '🏪',
    type: BadgeType.explorer,
    requirementCount: 3,
  );
  
  static final seasonalMaster = Badge(
    id: 'seasonal_master',
    name: 'Seasonal Master',
    description: 'Complete all quests',
    icon: '🏆',
    type: BadgeType.master,
    requirementCount: 50,
  );
  
  static List<Badge> get all => [
    springExplorer,
    summerExplorer,
    autumnExplorer,
    winterExplorer,
    fruitCollector,
    vegetableCollector,
    marketExplorer,
    seasonalMaster,
  ];
}
