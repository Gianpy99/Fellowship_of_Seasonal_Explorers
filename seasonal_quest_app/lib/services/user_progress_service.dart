import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_progress.dart';

/// Service to handle user progress persistence via server
class UserProgressService {
  static const String _serverUrl = 'http://localhost:3000/api/progress';
  static const String _timeout = '10'; // seconds
  
  /// Load user progress from server
  static Future<UserProgress> loadUserProgress() async {
    try {
      final response = await http
          .get(Uri.parse(_serverUrl))
          .timeout(Duration(seconds: int.parse(_timeout)));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final progress = UserProgress.fromJson(json);
        return progress;
      } else {
        return UserProgress.empty();
      }
    } catch (e) {
      return UserProgress.empty();
    }
  }
  
  /// Save user progress to server
  static Future<bool> saveUserProgress(UserProgress progress) async {
    try {
      final payload = progress.toJson();
      
      final response = await http
          .post(
            Uri.parse(_serverUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: int.parse(_timeout)));
      
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
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
    return updated;
  }
  
  /// Mark a location as visited
  static Future<UserProgress> visitLocation(
    UserProgress progress,
    String locationId,
  ) async {
    final updated = progress.copyWithVisitedLocation(locationId);
    await saveUserProgress(updated);
    return updated;
  }
  
  /// Clear all user progress
  static Future<bool> clearAllProgress() async {
    try {
      final response = await http
          .delete(Uri.parse(_serverUrl))
          .timeout(Duration(seconds: int.parse(_timeout)));
      
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
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
