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
      print('🔄 Loading progress from server: $_serverUrl');
      final response = await http
          .get(Uri.parse(_serverUrl))
          .timeout(Duration(seconds: int.parse(_timeout)));
      
      print('📨 Server response code: ${response.statusCode}');
      print('📨 Server response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final progress = UserProgress.fromJson(json);
        print('✅ Loaded progress from server: ${progress.completedQuestIds.length} quests');
        return progress;
      } else {
        print('⚠️ Server error loading progress: ${response.statusCode}');
        return UserProgress.empty();
      }
    } catch (e) {
      print('⚠️ Error loading progress from server: $e');
      return UserProgress.empty();
    }
  }
  
  /// Save user progress to server
  static Future<bool> saveUserProgress(UserProgress progress) async {
    try {
      final payload = progress.toJson();
      print('📤 Sending progress to server: $payload');
      
      final response = await http
          .post(
            Uri.parse(_serverUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: int.parse(_timeout)));
      
      print('📨 Server response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200) {
        print('💾 Saved progress to server: ${progress.completedQuestIds.length} quests');
        return true;
      } else {
        print('❌ Server error saving progress: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error saving progress to server: $e');
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
        print('🗑️ Cleared all progress on server');
        return true;
      }
      return false;
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
