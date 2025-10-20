# Data Model: Seasonal Quest App

**Date**: 2025-10-20  
**Feature**: Seasonal Quest App for Family Education  
**Storage**: JSON files (local) + File System (photos)  
**Approach**: Simple, human-readable JSON files - no database needed for family scale

## Storage Philosophy

**Keep It Simple**: JSON files are sufficient for family use (<100 quests, <200 completions). No database complexity needed.

**Human-Readable**: Parents can inspect/backup files easily. No special tools required.

**No Cloud**: Everything stays on device. Zero internet dependency except optional AI recommendations.

## JSON File Structure

### 1. user_progress.json

**Purpose**: Track all quest completions, badges, and progress statistics

**Location**: `{app_data}/data/user_progress.json`

**Example**:
```json
{
  "profile_name": "Family",
  "language": "it",
  "completions": [
    {
      "id": "comp_uuid_1",
      "quest_id": "bergamotto_calabria",
      "completed_at": 1729449600,
      "latitude": 38.1157,
      "longitude": 15.6529,
      "photo_path": "photos/uuid-photo-1.jpg",
      "journal_text_it": "Abbiamo trovato bergamotti al mercato!",
      "journal_text_en": "We found bergamots at the market!",
      "was_manual_checkin": false
    }
  ],
  "badges_earned": [
    {
      "badge_id": "first_explorer",
      "earned_at": 1729449600,
      "celebration_seen": true
    }
  ],
  "stats": {
    "total_quests_completed": 1,
    "current_streak_days": 1,
    "longest_streak_days": 1,
    "last_quest_date": 1729449600,
    "total_photos_taken": 1,
    "total_journal_entries": 1,
    "by_season": {
      "spring": 0,
      "summer": 0,
      "autumn": 1,
      "winter": 0
    },
    "by_category": {
      "fruits": 1,
      "vegetables": 0,
      "flowers": 0,
      "animal_products": 0
    }
  },
  "last_ai_recommendation_at": null,
  "created_at": 1729449600,
  "updated_at": 1729449600
}
```

**Notes**:
- Single file containing all user data
- Load once at startup, keep in memory
- Save on every quest completion or badge earn
- Timestamps are Unix epoch (seconds since 1970)

---

### 2. settings.json

**Purpose**: App preferences and parental controls

**Location**: `{app_data}/data/settings.json`

**Example**:
```json
{
  "language": "it",
  "enable_ai_recommendations": false,
  "enable_location_services": true,
  "enable_notifications": true,
  "photo_quality": "medium",
  "current_region": "calabria",
  "parental_controls_enabled": false,
  "parental_pin_hash": null,
  "created_at": 1729449600,
  "updated_at": 1729449600
}
```

**Validation**:
- `language`: "it" or "en"
- `photo_quality`: "low", "medium", or "high"
- `current_region`: "calabria" or "south_england"

---

### 3. ai_recommendations.json (Optional)

**Purpose**: Cache Gemini AI quest suggestions

**Location**: `{app_data}/data/ai_recommendations.json`

**Example**:
```json
{
  "generated_at": 1729449600,
  "expires_at": 1729536000,
  "context": {
    "season": "autumn",
    "region": "calabria",
    "weather": "sunny",
    "completed_count": 5
  },
  "recommended_quest_ids": [
    "cipolla_rossa_calabria",
    "finocchio_calabria",
    "cavolfiore_calabria"
  ],
  "was_accepted": false
}
```

**Notes**:
- Created only if AI recommendations enabled in settings
- Expires after 24 hours (86400 seconds)
- Deleted if expired on next app launch

---

### 4. quests_[region].json (Bundled Assets)

**Purpose**: Static quest data bundled with app

**Location**: `assets/data/quests_calabria.json`, `assets/data/quests_england.json`

**Example**:
```json
{
  "quests": [
    {
      "id": "bergamotto_calabria",
      "title_it": "Bergamotto",
      "title_en": "Bergamot",
      "description_it": "C'era una volta, tra gli ulivi...",
      "description_en": "Once upon a time, among olive trees...",
      "category": "fruits",
      "season": "winter",
      "region": "calabria",
      "difficulty": "medium",
      "estimated_minutes": 15,
      "educational_content_it": "Il bergamotto è tipico della Calabria...",
      "educational_content_en": "Bergamot is typical of Calabria...",
      "icon_path": "assets/images/icons/bergamotto.png",
      "story_image_path": "assets/images/story_scenes/bergamot_story1.png",
      "recipe_image_path": "assets/images/recipes/bergamot_recipe1.png",
      "character_name": "Lina",
      "latitude": null,
      "longitude": null,
      "location_radius_meters": 100,
      "requires_location": true
    }
  ],
  "characters": [
    {
      "name": "Lina",
      "description_it": "Bambina curiosa della Calabria",
      "description_en": "Curious girl from Calabria",
      "avatar_path": "assets/characters/lina.png",
      "personality_trait": "curious",
      "home_region": "calabria"
    }
  ],
  "badges": [
    {
      "id": "first_explorer",
      "name_it": "Primo Esploratore",
      "name_en": "First Explorer",
      "description_it": "Completa la tua prima missione",
      "description_en": "Complete your first quest",
      "icon_path": "assets/badges/first_explorer.png",
      "category": "milestone",
      "requirement_type": "quest_count",
      "requirement_value": 1,
      "rarity": "common",
      "sort_order": 1
    }
  ]
}
```

**Notes**:
- Read-only asset bundled with app
- Load once at startup, cache in memory
- Never modified by user

---

## Relationships Diagram (Conceptual - No Foreign Keys)

```
quests_calabria.json ──┬──> Defines available quests
                       ├──> Defines story characters
                       └──> Defines badge criteria

user_progress.json ────┬──> References quest_id (string match)
                       └──> References badge_id (string match)

settings.json ─────────> Standalone configuration

ai_recommendations.json ──> References quest_id (string array)
```

---

## Data Access Patterns

### App Startup Flow
```dart
// 1. Load static quest data (from assets)
final questsJson = await rootBundle.loadString('assets/data/quests_calabria.json');
final questData = json.decode(questsJson);
final quests = questData['quests'].map((q) => Quest.fromJson(q)).toList();

// 2. Load user progress (from app data directory)
final appDir = await getApplicationDocumentsDirectory();
final progressFile = File('${appDir.path}/data/user_progress.json');
if (await progressFile.exists()) {
  final progressJson = await progressFile.readAsString();
  final progress = UserProgress.fromJson(json.decode(progressJson));
} else {
  // First launch: create default progress
  final progress = UserProgress.initial();
}

// 3. Load settings
final settingsFile = File('${appDir.path}/data/settings.json');
// ... similar pattern
```

### Quest Completion Flow
```dart
// 1. User completes quest
final completion = QuestCompletion(
  id: Uuid().v4(),
  questId: 'bergamotto_calabria',
  completedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  photoPath: 'photos/uuid-photo.jpg',
  // ... other fields
);

// 2. Update progress in memory
userProgress.completions.add(completion);
userProgress.stats.totalQuestsCompleted++;
userProgress.stats.byCategory['fruits']++;

// 3. Check for new badges
if (userProgress.stats.totalQuestsCompleted == 1) {
  userProgress.badgesEarned.add(UserBadge(
    badgeId: 'first_explorer',
    earnedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  ));
}

// 4. Save to JSON file
final progressFile = File('${appDir.path}/data/user_progress.json');
await progressFile.writeAsString(
  json.encode(userProgress.toJson()),
);
```

### Photo Management
```dart
// Save photo with compression
final photo = await ImagePicker().pickImage(source: ImageSource.camera);
final compressed = await FlutterImageCompress.compressAndGetFile(
  photo!.path,
  '${appDir.path}/photos/${Uuid().v4()}.jpg',
  quality: 85,
);
```

---

## Data Models (Dart Classes)

### Quest
```dart
class Quest {
  final String id;
  final String titleIt;
  final String titleEn;
  final String descriptionIt;
  final String descriptionEn;
  final String category;
  final String season;
  final String region;
  final String difficulty;
  final int estimatedMinutes;
  final String educationalContentIt;
  final String educationalContentEn;
  final String iconPath;
  final String storyImagePath;
  final String? recipeImagePath;
  final String characterName;
  final double? latitude;
  final double? longitude;
  final int locationRadiusMeters;
  final bool requiresLocation;

  Quest.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        titleIt = json['title_it'],
        // ... map all fields
        
  Map<String, dynamic> toJson() => {
        'id': id,
        'title_it': titleIt,
        // ... all fields
      };
}
```

### QuestCompletion
```dart
class QuestCompletion {
  final String id;
  final String questId;
  final int completedAt;
  final double? latitude;
  final double? longitude;
  final String? photoPath;
  final String? journalTextIt;
  final String? journalTextEn;
  final bool wasManualCheckin;

  QuestCompletion.fromJson(Map<String, dynamic> json) // ...
  Map<String, dynamic> toJson() => // ...
}
```

### UserProgress
```dart
class UserProgress {
  final String profileName;
  final String language;
  final List<QuestCompletion> completions;
  final List<UserBadge> badgesEarned;
  final ProgressStats stats;
  final int? lastAiRecommendationAt;
  final int createdAt;
  final int updatedAt;

  UserProgress.fromJson(Map<String, dynamic> json) // ...
  Map<String, dynamic> toJson() => // ...
  
  factory UserProgress.initial() => UserProgress(
        profileName: 'Family',
        language: 'it',
        completions: [],
        badgesEarned: [],
        stats: ProgressStats.empty(),
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
}
```

---

## Validation Rules

### Quest Completion
- `quest_id` must exist in loaded quest list
- `completed_at` must be valid Unix timestamp
- `photo_path` must point to existing file if not null
- Either (`latitude` AND `longitude`) OR `was_manual_checkin=true`

### Badge Earning
- `badge_id` must exist in badge definitions
- Each badge can only be earned once (check before adding to list)

### Settings
- `language` enum: ["it", "en"]
- `photo_quality` enum: ["low", "medium", "high"]
- `current_region` enum: ["calabria", "south_england"]

---

## State Transitions

## State Transitions

### Streak Calculation
```dart
bool isStreakContinuing() {
  if (completions.isEmpty) return false;
  
  final lastQuestDate = DateTime.fromMillisecondsSinceEpoch(
    stats.lastQuestDate * 1000,
  );
  final yesterday = DateTime.now().subtract(Duration(days: 1));
  
  // Streak continues if quest was completed yesterday or today
  return lastQuestDate.year == yesterday.year &&
         lastQuestDate.month == yesterday.month &&
         lastQuestDate.day == yesterday.day;
}

void updateStreak() {
  if (isStreakContinuing()) {
    stats.currentStreakDays++;
    if (stats.currentStreakDays > stats.longestStreakDays) {
      stats.longestStreakDays = stats.currentStreakDays;
    }
  } else {
    stats.currentStreakDays = 1; // Reset to 1 (today's quest)
  }
}
```

### Badge Evaluation
```dart
void checkAndAwardBadges() {
  final badges = loadedQuestData.badges;
  
  for (final badge in badges) {
    // Skip if already earned
    if (badgesEarned.any((b) => b.badgeId == badge.id)) continue;
    
    bool shouldAward = false;
    
    switch (badge.requirementType) {
      case 'quest_count':
        shouldAward = stats.totalQuestsCompleted >= badge.requirementValue;
        break;
      case 'streak_days':
        shouldAward = stats.currentStreakDays >= badge.requirementValue;
        break;
      case 'season_complete':
        final seasonKey = badge.id.split('_')[0]; // e.g., 'autumn' from 'autumn_master'
        final totalSeasonQuests = loadedQuests.where((q) => q.season == seasonKey).length;
        shouldAward = stats.bySeason[seasonKey] >= totalSeasonQuests;
        break;
      case 'category_complete':
        final category = badge.id.split('_')[0]; // e.g., 'fruit' from 'fruit_expert'
        final totalCategoryQuests = loadedQuests.where((q) => q.category == category).length;
        shouldAward = stats.byCategory[category] >= totalCategoryQuests;
        break;
    }
    
    if (shouldAward) {
      badgesEarned.add(UserBadge(
        badgeId: badge.id,
        earnedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        celebrationSeen: false,
      ));
    }
  }
}
```

---

## File System Structure

```
{app_documents_directory}/
├── data/
│   ├── user_progress.json       # ~5-50KB (grows with completions)
│   ├── settings.json            # ~1KB
│   └── ai_recommendations.json  # ~2KB (optional, ephemeral)
├── photos/
│   ├── {uuid-1}.jpg            # ~400KB each (compressed)
│   ├── {uuid-2}.jpg
│   └── ...
└── exports/
    └── journal_2025-10-20.pdf   # Generated on-demand

{app_bundle_assets}/
├── data/
│   ├── quests_calabria.json    # ~160KB (80 quests)
│   └── quests_england.json     # ~160KB
└── images/
    ├── icons/                   # From Python pipeline
    ├── story_scenes/
    ├── recipes/
    ├── badges/
    └── characters/
```

---

## Privacy & Safety

### No Cloud, No Database
- All JSON files stored in app-scoped directory (not accessible to other apps)
- Photos stored with UUID filenames (no metadata leakage)
- No network requests except optional AI (disabled by default, parental opt-in)
- No user accounts, no authentication

### Data Portability
- JSON format is human-readable and portable
- Parents can backup files via file manager
- Export functionality creates PDFs from JSON data

### Data Deletion
```dart
// "Clear All Data" button in settings
Future<void> clearAllData() async {
  final appDir = await getApplicationDocumentsDirectory();
  
  // Delete JSON files
  await File('${appDir.path}/data/user_progress.json').delete();
  await File('${appDir.path}/data/settings.json').delete();
  
  // Delete all photos
  final photosDir = Directory('${appDir.path}/photos');
  if (await photosDir.exists()) {
    await photosDir.delete(recursive: true);
  }
  
  // Reset to initial state
  final freshProgress = UserProgress.initial();
  final freshSettings = AppSettings.defaults();
}
```

---

## Performance Estimates

### File Sizes (Family Scale)
- **user_progress.json**: ~50KB (100 completions with journal entries)
- **settings.json**: ~1KB
- **quests_calabria.json**: ~160KB (bundled asset, 80 quests)
- **Total JSON**: ~211KB (negligible)
- **Photos**: ~40MB (100 photos × 400KB)
- **Total Storage**: ~40MB for typical family use

### Load Times
- **Parse quests JSON**: <100ms (once at startup, cached)
- **Load user progress**: <50ms (small JSON file)
- **Save progress**: <20ms (atomic write)
- **All startup I/O**: <200ms total

### Scalability
- Comfortable up to 500 quest completions (~250KB JSON)
- Photo storage is limiting factor (not JSON size)
- If needed, can shard completions into yearly files
- But for family use, single file sufficient

---

## Migration Path (If Needed)

If family use expands beyond comfort zone (~500 completions):
1. **Shard by year**: `user_progress_2025.json`, `user_progress_2026.json`
2. **Compress old data**: gzip older year files
3. **Or migrate to SQLite**: Use `sqflite` package, import JSON data
4. **Or export archives**: Create yearly PDF albums, archive old JSON

But for typical family use (2-5 sessions/week), single JSON file will last years.

---

**Bottom Line**: JSON files are simple, transparent, and sufficient. No database complexity needed for family-scale app.
