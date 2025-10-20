import 'badge.dart';

/// Tracks user progress across all quests
class UserProgress {
  final List<String> completedQuestIds;
  final List<String> visitedLocationIds;
  final List<Badge> unlockedBadges;
  final DateTime lastUpdated;
  
  UserProgress({
    required this.completedQuestIds,
    required this.visitedLocationIds,
    required this.unlockedBadges,
    required this.lastUpdated,
  });
  
  /// Empty progress for new users
  factory UserProgress.empty() {
    return UserProgress(
      completedQuestIds: [],
      visitedLocationIds: [],
      unlockedBadges: [],
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Check if quest is completed
  bool isQuestCompleted(String questId) {
    return completedQuestIds.contains(questId);
  }
  
  /// Check if location is visited
  bool isLocationVisited(String locationId) {
    return visitedLocationIds.contains(locationId);
  }
  
  /// Check if badge is unlocked
  bool isBadgeUnlocked(String badgeId) {
    return unlockedBadges.any((badge) => badge.id == badgeId);
  }
  
  /// Get completion percentage (0-100)
  double getCompletionPercentage(int totalQuests) {
    if (totalQuests == 0) return 0.0;
    return (completedQuestIds.length / totalQuests) * 100;
  }
  
  /// Add completed quest
  UserProgress copyWithCompletedQuest(String questId) {
    if (completedQuestIds.contains(questId)) return this;
    
    return UserProgress(
      completedQuestIds: [...completedQuestIds, questId],
      visitedLocationIds: visitedLocationIds,
      unlockedBadges: unlockedBadges,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Add visited location
  UserProgress copyWithVisitedLocation(String locationId) {
    if (visitedLocationIds.contains(locationId)) return this;
    
    return UserProgress(
      completedQuestIds: completedQuestIds,
      visitedLocationIds: [...visitedLocationIds, locationId],
      unlockedBadges: unlockedBadges,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Add unlocked badge
  UserProgress copyWithUnlockedBadge(Badge badge) {
    if (isBadgeUnlocked(badge.id)) return this;
    
    return UserProgress(
      completedQuestIds: completedQuestIds,
      visitedLocationIds: visitedLocationIds,
      unlockedBadges: [...unlockedBadges, badge],
      lastUpdated: DateTime.now(),
    );
  }
  
  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      completedQuestIds: (json['completed_quest_ids'] as List).cast<String>(),
      visitedLocationIds: (json['visited_location_ids'] as List).cast<String>(),
      unlockedBadges: (json['unlocked_badges'] as List)
          .map((badge) => Badge.fromJson(badge as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'completed_quest_ids': completedQuestIds,
      'visited_location_ids': visitedLocationIds,
      'unlocked_badges': unlockedBadges.map((badge) => badge.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
