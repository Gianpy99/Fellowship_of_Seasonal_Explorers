import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quest.dart';
import '../services/gemini_image_service.dart';
import '../services/simple_image_service.dart';

/// Detail screen for a single quest with story, images, and Street View
class QuestDetailScreen extends StatefulWidget {
  final Quest quest;
  final bool isCompleted;
  final VoidCallback onComplete;
  
  const QuestDetailScreen({
    super.key,
    required this.quest,
    required this.isCompleted,
    required this.onComplete,
  });
  
  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  int _currentStoryIndex = 0;
  bool _isGeneratingImage = false;
  
  // Cached generated images (loaded from IndexedDB)
  Uint8List? _cachedIconImage;
  Map<int, Uint8List> _cachedStoryImages = {};
  
  @override
  void initState() {
    super.initState();
    _loadCachedImages();
  }
  
  @override
  void didUpdateWidget(covariant QuestDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload images if quest changed or after hot reload
    if (oldWidget.quest.id != widget.quest.id) {
      _cachedIconImage = null;
      _cachedStoryImages.clear();
      _loadCachedImages();
    }
  }
  
  /// Load story image from server if not in local cache
  Future<Uint8List?> _loadStoryImageFromServer(int storyIndex) async {
    try {
      final storyCacheKey = SimpleImageService.cacheKey(
        widget.quest.id,
        'story',
        index: storyIndex,
      );
      
      final imageBytes = await SimpleImageService.getImageFromCache(storyCacheKey);
      if (imageBytes != null && mounted) {
        // Cache it locally so we don't refetch
        setState(() => _cachedStoryImages[storyIndex] = imageBytes);
        print('🌐 Loaded story $storyIndex from server (via FutureBuilder)');
        return imageBytes;
      }
    } catch (e) {
      print('⚠️ Error loading story $storyIndex from server: $e');
    }
    return null;
  }
  
  /// Show image in fullscreen modal
  void _showFullscreenImage(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full screen image
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: InteractiveViewer(
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ),
            
            // Instructions
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Text(
                      '🔍 Pinch to zoom • Drag to pan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        backgroundColor: Colors.black45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click to close',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Load images: Try JSON first (persistent), then assets, then server
  Future<void> _loadCachedImages() async {
    // 1. Try loading icon from JSON (persistent across sessions!)
    if (widget.quest.cachedIconBase64 != null) {
      try {
        final bytes = base64Decode(widget.quest.cachedIconBase64!);
        if (mounted) {
          setState(() => _cachedIconImage = bytes);
          print('� Loaded icon from JSON: ${widget.quest.nameIt}');
          return; // Found it!
        }
      } catch (e) {
        print('⚠️ Error decoding icon from JSON: $e');
      }
    }
    
    // 2. Try loading icon from assets
    final iconPath = SimpleImageService.assetPath(widget.quest.id, 'icon');
    try {
      final data = await rootBundle.load(iconPath);
      if (mounted) {
        setState(() => _cachedIconImage = data.buffer.asUint8List());
        print('📂 Loaded icon from assets: ${widget.quest.nameIt}');
        return; // Found it!
      }
    } catch (e) {
      print('ℹ️ No icon in assets for ${widget.quest.nameIt}');
    }
    
    // 3. Try loading icon from server (persists across flutter run instances!)
    final iconCacheKey = SimpleImageService.cacheKey(widget.quest.id, 'icon');
    try {
      final imageBytes = await SimpleImageService.getImageFromCache(iconCacheKey);
      if (imageBytes != null) {
        if (mounted) {
          setState(() => _cachedIconImage = imageBytes);
          print('🌐 Loaded icon from server: ${widget.quest.nameIt}');
          return; // Found it!
        }
      }
    } catch (e) {
      print('⚠️ Error loading icon from server: $e');
    }
    
    // 4. Load story images from JSON (persistent!)
    if (widget.quest.cachedStoryBase64 != null) {
      for (int i = 0; i < widget.quest.cachedStoryBase64!.length; i++) {
        try {
          final bytes = base64Decode(widget.quest.cachedStoryBase64![i]);
          if (mounted) {
            setState(() => _cachedStoryImages[i] = bytes);
            print('✅ Loaded story $i from JSON: ${widget.quest.nameIt}');
          }
        } catch (e) {
          print('⚠️ Error decoding story $i from JSON: $e');
        }
      }
    }
    
    // 5. Load story images from server (persists across flutter run instances!)
    for (int i = 0; i < widget.quest.storyIt.length; i++) {
      if (_cachedStoryImages.containsKey(i)) continue; // Skip if already loaded
      
      final storyCacheKey = SimpleImageService.cacheKey(
        widget.quest.id,
        'story',
        index: i,
      );
      
      try {
        final imageBytes = await SimpleImageService.getImageFromCache(storyCacheKey);
        if (imageBytes != null) {
          if (mounted) {
            setState(() => _cachedStoryImages[i] = imageBytes);
            print('🌐 Loaded story $i from server: ${widget.quest.nameIt}');
          }
        }
      } catch (e) {
        print('⚠️ Error loading story $i from server: $e');
      }
    }
  }
  
  void _openStreetView() {
    // Use real town coordinates for Street View
    final coords = widget.quest.coordinates;
    final url = 'https://www.google.com/maps/@?api=1&map_action=pano'
                '&viewpoint=${coords.latitude},${coords.longitude}';
    html.window.open(url, '_blank', 'width=1200,height=800');
    
    _showStreetViewDialog();
  }
  
  void _openGoogleMaps() {
    // Use real town coordinates for Google Maps
    final coords = widget.quest.coordinates;
    final url = 'https://www.google.com/maps/search/?api=1'
                '&query=${coords.latitude},${coords.longitude}';
    html.window.open(url, '_blank');
  }
  
  void _showStreetViewDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.streetview, color: Colors.orange),
            SizedBox(width: 8),
            Text('Virtual Exploration'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📍 ${widget.quest.location.name}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              widget.quest.location.address,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            SizedBox(height: 16),
            Text(
              '💡 Tips:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text('• Use arrow keys or mouse to navigate in Street View', style: TextStyle(fontSize: 13)),
            Text('• Look for the market stalls and seasonal products', style: TextStyle(fontSize: 13)),
            Text('• Accept Google Maps Terms of Service if prompted', style: TextStyle(fontSize: 13)),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _openGoogleMaps,
                icon: Icon(Icons.map, size: 18),
                label: Text('Open in Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _uploadIconImage() async {
    try {
      // Create file input element
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      
      await input.onChange.first;
      
      if (input.files!.isEmpty) return;
      
      final file = input.files!.first;
      final reader = html.FileReader();
      
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      
      final bytes = reader.result as List<int>;
      final base64Data = base64Encode(bytes);
      
      // Generate filename
      final filename = GeminiImageService.generateFilename(widget.quest, 'icon');
      
      // Save to memory cache + automatic download
      final cacheKey = SimpleImageService.cacheKey(widget.quest.id, 'icon');
      await SimpleImageService.saveImage(cacheKey, base64Data, filename);
      
      // Update UI immediately
      if (mounted) {
        setState(() => _cachedIconImage = Uint8List.fromList(bytes));
      }
      
      // Show success message
      _showSuccessMessage(
        '✅ Icon uploaded!\n'
        'File saved as: $filename\n'
        'Copy to: assets/images/generated/$filename'
      );
    } catch (e) {
      _showErrorDialog('Error uploading image: $e');
    }
  }
  
  Future<void> _uploadStoryImage() async {
    try {
      // Create file input element
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      
      await input.onChange.first;
      
      if (input.files!.isEmpty) return;
      
      final file = input.files!.first;
      final reader = html.FileReader();
      
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      
      final bytes = reader.result as List<int>;
      final base64Data = base64Encode(bytes);
      
      // Generate filename
      final filename = GeminiImageService.generateFilename(
        widget.quest, 
        'story',
        variation: _currentStoryIndex,
      );
      
      // Save to memory cache + automatic download
      final cacheKey = SimpleImageService.cacheKey(
        widget.quest.id, 
        'story', 
        index: _currentStoryIndex
      );
      await SimpleImageService.saveImage(cacheKey, base64Data, filename);
      
      // Update UI immediately
      if (mounted) {
        setState(() => _cachedStoryImages[_currentStoryIndex] = Uint8List.fromList(bytes));
      }
      
      // Show success message
      _showSuccessMessage(
        '✅ Story image uploaded!\n'
        'File saved as: $filename\n'
        'Copy to: assets/images/generated/$filename'
      );
    } catch (e) {
      _showErrorDialog('Error uploading image: $e');
    }
  }
  
  Future<void> _generateIconImage() async {
    if (_isGeneratingImage) return;
    
    // Show prompt editor dialog
    final customPrompt = await _showPromptEditor(
      'Icon Prompt',
      widget.quest.customIconPrompt ?? GeminiImageService.buildIconPrompt(widget.quest),
      'icon',
    );
    
    if (customPrompt == null) return; // User cancelled
    
    setState(() => _isGeneratingImage = true);
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating Icon...'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎨 Using Imagen 3 (Google AI)'),
              SizedBox(height: 8),
              Text('🍎 Product: ${widget.quest.nameIt}'),
              SizedBox(height: 8),
              Text('⏳ Creating centered icon illustration...'),
            ],
          ),
        ),
      );
      
      // Generate icon image
      final imageData = await GeminiImageService.generateIconImage(
        widget.quest,
        customPrompt: customPrompt,
      );
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (imageData != null) {
        // Generate filename
        final filename = GeminiImageService.generateFilename(widget.quest, 'icon');
        
        // Save to memory cache + automatic download
        final cacheKey = SimpleImageService.cacheKey(widget.quest.id, 'icon');
        await SimpleImageService.saveImage(cacheKey, imageData, filename);
        
        // Update UI immediately
        final bytes = base64Decode(imageData);
        if (mounted) {
          setState(() => _cachedIconImage = bytes);
        }
        
        _showSuccessMessage('✅ Icon saved! Persists via LocalStorage 🎉');
      } else {
        _showErrorDialog('Failed to generate icon. Please try again.');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }
  
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );
  }
  
  Future<void> _generateAIImage() async {
    if (_isGeneratingImage) return;
    
    setState(() => _isGeneratingImage = true);
    
    try {
      // Get default prompt
      final story = widget.quest.storyIt[_currentStoryIndex];
      final defaultPrompt = widget.quest.customStoryPrompt ?? 
        GeminiImageService.buildStoryPrompt(widget.quest, story, _currentStoryIndex);
      
      // Show prompt editor first
      final customPrompt = await _showPromptEditor(
        'Edit Story Image Prompt',
        defaultPrompt,
        'custom_story_prompt',
      );
      
      if (customPrompt == null) {
        setState(() => _isGeneratingImage = false);
        return; // User cancelled
      }
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Generating AI Image...'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🎨 Using Gemini 2.5 Flash Image'),
              SizedBox(height: 8),
              Text('📖 Story: ${widget.quest.storyIt[_currentStoryIndex].substring(0, 50)}...'),
              SizedBox(height: 8),
              Text('⏳ This may take 10-30 seconds...'),
            ],
          ),
        ),
      );
      
      // Generate image using custom prompt
      final imageData = await GeminiImageService.generateStoryImage(
        widget.quest,
        story,
        variationIndex: _currentStoryIndex,
        customPrompt: customPrompt,
      );
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      if (imageData != null) {
        // Generate filename
        final filename = GeminiImageService.generateFilename(
          widget.quest,
          'story',
          variation: _currentStoryIndex,
        );
        
        // Save to memory cache + automatic download
        final cacheKey = SimpleImageService.cacheKey(
          widget.quest.id, 
          'story', 
          index: _currentStoryIndex
        );
        await SimpleImageService.saveImage(cacheKey, imageData, filename);
        
        // Update UI immediately
        final bytes = base64Decode(imageData);
        if (mounted) {
          setState(() => _cachedStoryImages[_currentStoryIndex] = bytes);
        }
        
        _showSuccessMessage('✅ Story saved! Persists via LocalStorage 🎉');
      } else {
        // Show error
        _showErrorDialog('Failed to generate image. Please try again.');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Error: $e');
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('❌ Generation Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Show dialog to edit AI generation prompt
  Future<String?> _showPromptEditor(String title, String defaultPrompt, String promptType) async {
    final controller = TextEditingController(text: defaultPrompt);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Colors.purple),
            SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: Container(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize the AI prompt for better results:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 12,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your custom prompt...',
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Tip: Be specific about style, colors, composition, and mood.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Changes will be saved to JSON for future use',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.text = defaultPrompt;
            },
            child: Text('Reset to Default'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final prompt = controller.text.trim();
              if (prompt.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Prompt cannot be empty')),
                );
                return;
              }
              
              Navigator.of(context).pop(prompt);
            },
            icon: Icon(Icons.check),
            label: Text('Use This Prompt'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
  
  void _completeQuest() {
    if (widget.isCompleted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 Quest Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'ve successfully explored ${widget.quest.nameIt}!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Icon(Icons.check_circle, color: Colors.green, size: 64),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Save quest completion to SharedPreferences
              // Note: We need to get current progress from parent
              // For now, just save and call callback
              print('✅ Quest marked as complete: ${widget.quest.id}');
              widget.onComplete();
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Back to home screen
            },
            child: Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final currentStory = widget.quest.storyIt[_currentStoryIndex % widget.quest.storyIt.length];
    final seasonStatus = widget.quest.getSeasonName();
    final isInSeason = seasonStatus == 'In season' || seasonStatus == 'In harvest!';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quest.nameIt),
        backgroundColor: Colors.green,
        actions: [
          if (widget.isCompleted)
            Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.check_circle, color: Colors.white),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image
            Container(
              height: 200,
              color: Colors.green.shade50,
              child: _cachedIconImage != null
                  ? Image.memory(
                      _cachedIconImage!,
                      fit: BoxFit.contain,
                    )
                  : Center(
                      child: Text(
                        widget.quest.categoryEmoji,
                        style: TextStyle(fontSize: 120),
                      ),
                    ),
            ),
            
            // Season Status Banner
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              color: isInSeason ? Colors.green : Colors.grey,
              child: Center(
                child: Text(
                  seasonStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            // Info Section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.quest.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${widget.quest.nameEn}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Description
                  Text(
                    widget.quest.notesIt,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  
                  // Generate Icon Button + Upload Button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _generateIconImage,
                          icon: Icon(Icons.palette, size: 20),
                          label: Text('Generate Icon'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: BorderSide(color: Colors.blue),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _uploadIconImage,
                          icon: Icon(Icons.upload_file, size: 20),
                          label: Text('Upload Icon'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Educational Text
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school, color: Colors.amber.shade700),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.quest.educationalText,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Location Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.quest.townEmoji,
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quest.localTown ?? widget.quest.location.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.quest.localTown != null)
                              Text(
                                'Calabria, Italia',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              )
                            else
                              Text(
                                widget.quest.location.address,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  
                  // Street View Button
                  ElevatedButton.icon(
                    onPressed: _openStreetView,
                    icon: Icon(Icons.streetview),
                    label: Text('Explore in Street View'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
            
            // Story Section
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book, color: Colors.purple.shade700),
                      SizedBox(width: 8),
                      Text(
                        'Story from Calabria',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Story Image (if available) - Tap to fullscreen
                  if (_cachedStoryImages.containsKey(_currentStoryIndex)) ...[
                    GestureDetector(
                      onTap: () => _showFullscreenImage(_cachedStoryImages[_currentStoryIndex]!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: Colors.purple.shade50,
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          child: Image.memory(
                            _cachedStoryImages[_currentStoryIndex]!,
                            fit: BoxFit.contain,
                            key: ValueKey('story_${_currentStoryIndex}_${_cachedStoryImages[_currentStoryIndex].hashCode}'),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Tap image to view fullscreen',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ] else ...[
                    // Try loading from server if not in cache
                    FutureBuilder<Uint8List?>(
                      future: _loadStoryImageFromServer(_currentStoryIndex),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            color: Colors.purple.shade50,
                            width: double.infinity,
                            height: 300,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        
                        if (snapshot.hasData && snapshot.data != null) {
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () => _showFullscreenImage(snapshot.data!),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    color: Colors.purple.shade50,
                                    width: double.infinity,
                                    padding: EdgeInsets.all(16),
                                    child: Image.memory(
                                      snapshot.data!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Center(
                                child: Text(
                                  'Tap image to view fullscreen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple.shade400,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          );
                        }
                        
                        return SizedBox.shrink();
                      },
                    ),
                  ],
                  
                  Text(
                    currentStory,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.purple.shade900,
                    ),
                  ),
                  if (widget.quest.storyIt.length > 1) ...[
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentStoryIndex > 0
                              ? () => setState(() => _currentStoryIndex--)
                              : null,
                          icon: Icon(Icons.arrow_back),
                        ),
                        Text(
                          '${_currentStoryIndex + 1} / ${widget.quest.storyIt.length}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: _currentStoryIndex < widget.quest.storyIt.length - 1
                              ? () => setState(() => _currentStoryIndex++)
                              : null,
                          icon: Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    // AI Image Generation + Upload Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _generateAIImage,
                            icon: Icon(Icons.auto_awesome),
                            label: Text('Generate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              minimumSize: Size(double.infinity, 48),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _uploadStoryImage,
                            icon: Icon(Icons.upload_file),
                            label: Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: Size(double.infinity, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Complete Button
            if (!widget.isCompleted)
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _completeQuest,
                  icon: Icon(Icons.check_circle_outline),
                  label: Text('Mark as Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 56),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
