import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../models/quest.dart';

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
  
  void _openStreetView() {
    final url = widget.quest.location.getStreetViewUrl();
    html.window.open(url, '_blank', 'width=1200,height=800');
    
    _showStreetViewDialog();
  }
  
  void _openGoogleMaps() {
    final url = widget.quest.location.getGoogleMapsUrl();
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
            onPressed: () {
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
              child: Center(
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
                        widget.quest.location.typeEmoji,
                        style: TextStyle(fontSize: 24),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quest.location.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
