import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_progress.dart';

/// Service to handle user progress persistence
class UserProgressService {
  static const String _storageKey = 'user_progress';
  
  /// Load user progress from SharedPreferences
  static Future<UserProgress> loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString == null) {
        print('📝 No saved progress found - creating empty progress');
        return UserProgress.empty();
      }
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final progress = UserProgress.fromJson(json);
      print('✅ Loaded user progress: ${progress.completedQuestIds.length} quests completed');
      return progress;
    } catch (e) {
      print('⚠️ Error loading user progress: $e');
      return UserProgress.empty();
    }
  }
  
  /// Save user progress to SharedPreferences
  static Future<bool> saveUserProgress(UserProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(progress.toJson());
      final saved = await prefs.setString(_storageKey, jsonString);
      
      if (saved) {
        print('💾 Saved progress: ${progress.completedQuestIds.length} quests');
      }
      return saved;
    } catch (e) {
      print('❌ Error saving user progress: $e');
      return false;
    }
  }
  
  /// Mark a quest as completed
  static Future<UserProgress> completeQuest(
    UserProgress progress,
    String questId,
  ) async {
    final updated = progress.copyWithCompletedQuest(questId);
    await saveUserProgress(updated);
    print('✅ Quest completed: $questId');
    return updated;
  }
  
  /// Mark a location as visited
  static Future<UserProgress> visitLocation(
    UserProgress progress,
    String locationId,
  ) async {
    final updated = progress.copyWithVisitedLocation(locationId);
    await saveUserProgress(updated);
    print('🗺️ Location visited: $locationId');
    return updated;
  }
  
  /// Clear all user progress (for testing/reset)
  static Future<bool> clearAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleared = await prefs.remove(_storageKey);
      print('🗑️ Cleared all user progress');
      return cleared;
    } catch (e) {
      print('❌ Error clearing progress: $e');
      return false;
    }
  }
  
  /// Get progress stats
  static Map<String, int> getStats(UserProgress progress) {
    return {
      'completed_quests': progress.completedQuestIds.length,
      'visited_locations': progress.visitedLocationIds.length,
      'unlocked_badges': progress.unlockedBadges.length,
    };
  }
}
