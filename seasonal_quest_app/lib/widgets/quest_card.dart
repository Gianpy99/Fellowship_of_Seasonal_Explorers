import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/quest.dart';
import '../services/simple_image_service.dart';

/// Reusable card widget for displaying quest information
class QuestCard extends StatefulWidget {
  final Quest quest;
  final bool isCompleted;
  final VoidCallback onTap;
  
  const QuestCard({
    super.key,
    required this.quest,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  State<QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<QuestCard> {
  Uint8List? _cachedImage;

  @override
  void initState() {
    super.initState();
    _loadCachedImage();
  }

  Future<void> _loadCachedImage() async {
    final cacheKey = SimpleImageService.cacheKey(widget.quest.id, 'icon');
    print('🔍 [${widget.quest.nameIt}] Checking cache for key: $cacheKey');
    
    // Check if cached (memory or SharedPreferences)
    final hasCache = await SimpleImageService.hasCachedImage(cacheKey);
    print('   Has cached image: $hasCache');
    
    if (hasCache) {
      // Get from cache
      final image = await SimpleImageService.getImageFromCache(cacheKey);
      print('   Got image bytes: ${image != null ? "${image.length} bytes" : "null"}');
      
      if (image != null && mounted) {
        print('   ✅ Setting cached image for ${widget.quest.nameIt}');
        setState(() => _cachedImage = image);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasonName = widget.quest.getSeasonName();
    final isInSeason = seasonName == 'In season' || seasonName == 'In harvest!';
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isInSeason 
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon/Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: 
                      // Priority 1: Cached image (from memory/LocalStorage)
                      _cachedImage != null
                      ? Image.memory(
                          _cachedImage!,
                          fit: BoxFit.cover,
                        )
                      // Priority 2: Asset image
                      : widget.quest.generatedIconPath != null
                      ? Image.asset(
                          widget.quest.generatedIconPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to emoji if image not found
                            return Center(
                              child: Text(
                                widget.quest.categoryEmoji,
                                style: TextStyle(fontSize: 40),
                              ),
                            );
                          },
                        )
                      // Priority 3: Emoji fallback
                      : Center(
                          child: Text(
                            widget.quest.categoryEmoji,
                            style: TextStyle(fontSize: 40),
                          ),
                        ),
                ),
              ),
              SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.quest.nameIt,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.quest.localTown ?? widget.quest.location.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // Season tag
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isInSeason ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            seasonName,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        if (widget.isCompleted)
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
