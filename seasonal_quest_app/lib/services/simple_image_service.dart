import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'image_server_service.dart';

/// Image service: Memory cache + IndexedDB (persistent!) + automatic download
class SimpleImageService {
  // Memory cache for current session (fast display)
  static final Map<String, Uint8List> _memoryCache = {};
  
  /// Save image: Memory cache + IndexedDB + automatic download
  static Future<void> saveImage(String key, String base64Data, String filename) async {
    try {
      print('📝 [saveImage] START: key=$key, filename=$filename, base64 length=${base64Data.length}');
      
      // 1. Decode to bytes
      final bytes = base64Decode(base64Data);
      print('   ✅ Decoded base64 to bytes: ${bytes.length} bytes');
      
      // 2. Save to memory cache (instant display)
      _memoryCache[key] = bytes;
      print('   💾 Saved to memory cache: $key');
      
      // 3. Save to server (PERSISTS between flutter run!)
      await ImageServerService.saveImage(key, base64Data);
      print('   💾 Saved to server');
      
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
      
      print('   📥 Auto-downloaded: $filename');
    } catch (e) {
      print('❌ Error saving image: $e');
    }
  }
  
  /// Get image from memory cache OR IndexedDB
  static Future<Uint8List?> getImageFromCache(String key) async {
    print('🔍 [getImageFromCache] key=$key');
    
    // Try memory first (fastest)
    if (_memoryCache.containsKey(key)) {
      print('   ✅ Found in memory cache');
      return _memoryCache[key];
    }
    
    // Try server (PERSISTS!)
    try {
      final base64Data = await ImageServerService.getImage(key);
      if (base64Data != null && base64Data.isNotEmpty) {
        print('   ✅ Found on server');
        final bytes = base64Decode(base64Data);
        _memoryCache[key] = bytes; // Cache for next access
        return bytes;
      }
    } catch (e) {
      print('   ⚠️ Server read error: $e');
    }
    
    print('   ❌ Not found in any storage');
    return null;
  }
  
  /// Check if image exists in cache (memory OR IndexedDB)
  static Future<bool> hasCachedImage(String key) async {
    print('   📋 [hasCachedImage] Checking key=$key');
    
    if (_memoryCache.containsKey(key)) {
      print('      ✅ Found in memory cache');
      return true;
    }
    
    try {
      final exists = await ImageServerService.hasImage(key);
      if (exists) {
        print('      ✅ Found on server');
      } else {
        print('      ❌ NOT found on server');
      }
      return exists;
    } catch (e) {
      print('      ⚠️ Error checking server: $e');
      return false;
    }
  }
  
  /// Clear memory cache
  static void clearMemoryCache() {
    _memoryCache.clear();
    print('🗑️ Memory cache cleared');
  }
  
  /// Clear server storage
  static Future<void> clearServer() async {
    await ImageServerService.clearAll();
    print('🗑️ Server storage cleared');
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
