import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/quest.dart';

/// Service for generating images using Google Gemini API
/// Uses Gemini 2.5 Flash Image for AI-powered image generation
class GeminiImageService {
  // Using Gemini 2.5 Flash Image for image generation
  static const String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent';
  
  /// Generate an icon image for a seasonal product
  /// Returns the base64-encoded PNG image data
  static Future<String?> generateIconImage(Quest quest, {String? customPrompt}) async {
    final prompt = customPrompt ?? _buildIconPrompt(quest);
    return await _generateImage(prompt);
  }
  
  /// Generate a story scene image for a seasonal product
  /// Returns the base64-encoded PNG image data
  static Future<String?> generateStoryImage(Quest quest, String story, {int variationIndex = 0, String? customPrompt}) async {
    final prompt = customPrompt ?? _buildStoryPrompt(quest, story, variationIndex);
    return await _generateImage(prompt);
  }
  
  /// Generate a recipe illustration for a seasonal product
  /// Returns the base64-encoded PNG image data
  static Future<String?> generateRecipeImage(Quest quest, {String? customPrompt}) async {
    final prompt = customPrompt ?? _buildRecipePrompt(quest);
    return await _generateImage(prompt);
  }
  
  /// Build default icon prompt (exposed for editing)
  static String buildIconPrompt(Quest quest) => _buildIconPrompt(quest);
  
  /// Build default story prompt (exposed for editing)
  static String buildStoryPrompt(Quest quest, String story, int variationIndex) => 
      _buildStoryPrompt(quest, story, variationIndex);
  
  /// Build default recipe prompt (exposed for editing)
  static String buildRecipePrompt(Quest quest) => _buildRecipePrompt(quest);
  
  /// Build prompt for product icon (512x512, centered, simple background)
  static String _buildIconPrompt(Quest quest) {
    return '''
A charming illustration in Studio Ghibli style of ${quest.nameIt} (${quest.nameEn}).
Simple, clean background with soft pastel colors.
The ${quest.nameIt} should be centered, beautifully detailed with watercolor texture.
Warm, inviting atmosphere suitable for educational children's content.
Square format, icon-style illustration.
''';
  }
  
  /// Build prompt for story scene (768x768, narrative illustration)
  static String _buildStoryPrompt(Quest quest, String story, int variationIndex) {
    final variations = [
      'sunset lighting with warm golden tones',
      'early morning mist with soft blue hues',
      'sparkles of magic in the air with ethereal glow',
      'colorful market background with bustling activity',
      'forest clearing with wildflowers and dappled sunlight',
    ];
    
    final variation = variations[variationIndex % variations.length];
    
    return '''
Beautiful whimsical illustration in Studio Ghibli style, Disney magic, and Tolkien fantasy aesthetic.
Scene depicting: $story
Main focus on ${quest.nameIt} (${quest.nameEn}).
Art style: watercolor texture, pastel colors, warm and inviting.
Setting: $variation
Include characters Lina (curious Calabrian girl) and Taro (traveling elf) if mentioned in the story.
Child-friendly, educational, storybook quality.
''';
  }
  
  /// Build prompt for recipe illustration (640x640, cooking scene)
  static String _buildRecipePrompt(Quest quest) {
    return '''
Beautiful cooking illustration in Studio Ghibli style showing ${quest.nameIt} (${quest.nameEn}).
Storybook recipe art with ingredients arranged beautifully.
Warm kitchen atmosphere with soft lighting.
Include traditional Calabrian cooking elements.
Watercolor texture, inviting and appetizing presentation.
Educational illustration for children learning about seasonal food.
''';
  }
  
  /// Core method to call Gemini API and generate image
  static Future<String?> _generateImage(String prompt) async {
    if (!ApiKeys.isConfigured) {
      return null;
    }
    
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=${ApiKeys.geminiApiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'responseModalities': ['image'],
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract image data from Gemini response
        // Gemini 2.5 Flash Image returns: {"candidates": [{"content": {"parts": [{"inlineData": {"mimeType": "image/png", "data": "..."}}]}}]}
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final inlineData = parts[0]['inlineData'];
            final imageData = inlineData?['data'] as String?;
            
            if (imageData != null && imageData.isNotEmpty) {
              return imageData;
            }
          }
        }
        
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// Save generated image to file system (browser downloads folder)
  /// Returns the filename used
  static String saveImageToDownloads(String base64Data, String filename) {
    // For Flutter Web, we'll use the browser's download mechanism
    // The actual file saving will be handled by the UI layer
    return filename;
  }
  
  /// Generate filename for product image
  static String generateFilename(Quest quest, String type, {int? variation}) {
    final productName = quest.nameEn.toLowerCase().replaceAll(' ', '_');
    final suffix = variation != null ? '_$variation' : '';
    return '${productName}_$type$suffix.png';
  }
}
