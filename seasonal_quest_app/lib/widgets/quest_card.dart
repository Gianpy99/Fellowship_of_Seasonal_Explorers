import 'package:flutter/material.dart';
import '../models/quest.dart';

/// Reusable card widget for displaying quest information
class QuestCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final seasonName = quest.getSeasonName();
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
        onTap: onTap,
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
                child: Center(
                  child: Text(
                    quest.categoryEmoji,
                    style: TextStyle(fontSize: 40),
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
                      quest.nameIt,
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
                            quest.location.name,
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
                        if (isCompleted)
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
