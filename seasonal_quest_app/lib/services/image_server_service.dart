import 'package:http/http.dart' as http;
import 'dart:convert';

/// Simple HTTP service to communicate with image server
class ImageServerService {
  static const String _baseUrl = 'http://localhost:3000/api/images';
  
  /// Save image to server
  static Future<bool> saveImage(String key, String base64Data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'data': base64Data}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// Get image from server
  static Future<String?> getImage(String key) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$key'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else if (response.statusCode == 404) {
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Check if image exists on server
  static Future<bool> hasImage(String key) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$key'),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Get all images metadata
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Stats error
    }
    return null;
  }
  
  /// Delete image from server
  static Future<bool> deleteImage(String key) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$key'),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  /// Clear all images on server
  static Future<bool> clearAll() async {
    try {
      final response = await http.delete(
        Uri.parse(_baseUrl),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
