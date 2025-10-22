import 'dart:convert';
import 'dart:html' as html; // ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:flutter/services.dart';
import 'image_server_service.dart';

/// Image service: Memory cache + IndexedDB (persistent!) + automatic download
class SimpleImageService {
  // Memory cache for current session (fast display)
  static final Map<String, Uint8List> _memoryCache = {};
  
  /// Save image: Memory cache + IndexedDB + automatic download
  static Future<void> saveImage(String key, String base64Data, String filename) async {
    try {
      // 1. Decode to bytes
      final bytes = base64Decode(base64Data);
      
      // 2. Save to memory cache (instant display)
      _memoryCache[key] = bytes;
      
      // 3. Save to server (PERSISTS between flutter run!)
      await ImageServerService.saveImage(key, base64Data);
      
      // 4. Automatic download
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..style.display = 'none';
      
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      // Error saving image
    }
  }
  
  /// Get image from memory cache OR IndexedDB
  static Future<Uint8List?> getImageFromCache(String key) async {
    // Try memory first (fastest)
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    
    // Try server (PERSISTS!)
    try {
      final base64Data = await ImageServerService.getImage(key);
      if (base64Data != null && base64Data.isNotEmpty) {
        final bytes = base64Decode(base64Data);
        _memoryCache[key] = bytes; // Cache for next access
        return bytes;
      }
    } catch (e) {
      // Server read error
    }
    
    return null;
  }
  
  /// Check if image exists in cache (memory OR IndexedDB)
  static Future<bool> hasCachedImage(String key) async {
    if (_memoryCache.containsKey(key)) {
      return true;
    }
    
    try {
      return await ImageServerService.hasImage(key);
    } catch (e) {
      return false;
    }
  }
  
  /// Clear memory cache
  static void clearMemoryCache() {
    _memoryCache.clear();
  }
  
  /// Clear server storage
  static Future<void> clearServer() async {
    await ImageServerService.clearAll();
  }
  
  /// Clear all caches
  static Future<void> clearAllCaches() async {
    clearMemoryCache();
    await clearServer();
  }
  
  /// Generate asset path for persistent storage
  /// NOTE: Flutter Web adds 'assets/' prefix automatically, so we don't include it
  static String assetPath(String productId, String type, {int? index}) {
    if (type == 'icon') {
      return 'images/generated/${productId}_icon.png';
    } else if (type == 'story') {
      return 'images/generated/${productId}_story_$index.png';
    } else if (type == 'recipe') {
      return 'images/generated/${productId}_recipe.png';
    }
    return '';
  }
  
  /// Generate cache key
  static String cacheKey(String productId, String type, {int? index}) {
    if (type == 'icon') {
      return '${productId}_icon';
    } else if (type == 'story') {
      return '${productId}_story_$index';
    } else if (type == 'recipe') {
      return '${productId}_recipe';
    }
    return '';
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getStats() async {
    int memoryBytes = 0;
    for (var bytes in _memoryCache.values) {
      memoryBytes += bytes.length;
    }
    
    final serverStats = await ImageServerService.getStats();
    
    return {
      'memory_count': _memoryCache.length,
      'memory_mb': (memoryBytes / (1024 * 1024)).toStringAsFixed(2),
      'server_count': serverStats?['images'] ?? 0,
      'server_mb': serverStats?['size_mb'] ?? 0,
    };
  }
}
