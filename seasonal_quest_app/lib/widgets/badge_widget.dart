import 'package:flutter/material.dart';
import '../models/badge.dart' as models;

/// Reusable widget for displaying achievement badges
class BadgeWidget extends StatelessWidget {
  final models.Badge badge;
  final int currentProgress; // Number of quests completed for this badge
  final VoidCallback? onTap;

  const BadgeWidget({
    super.key,
    required this.badge,
    required this.currentProgress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercentage = (currentProgress / badge.requirementCount).clamp(0.0, 1.0);

    return Card(
      elevation: badge.isUnlocked ? 6 : 2,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 140,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle with progress
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: progressPercentage,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        badge.isUnlocked ? Colors.amber : Colors.blue,
                      ),
                    ),
                  ),
                  // Icon/Emoji
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: badge.isUnlocked
                          ? Colors.amber.shade50
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        badge.icon,
                        style: TextStyle(
                          fontSize: 32,
                          color: badge.isUnlocked ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  // Checkmark if unlocked
                  if (badge.isUnlocked)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),

              // Badge Name
              Text(
                badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: badge.isUnlocked ? Colors.black : Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),

              // Progress Text
              Text(
                badge.isUnlocked
                    ? 'Unlocked!'
                    : '$currentProgress/${badge.requirementCount}',
                style: TextStyle(
                  fontSize: 11,
                  color: badge.isUnlocked ? Colors.green : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrollable badge showcase
class BadgeShowcase extends StatelessWidget {
  final List<models.Badge> badges;
  final Map<String, int> progressMap; // badgeId -> currentProgress

  const BadgeShowcase({
    super.key,
    required this.badges,
    required this.progressMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          final progress = progressMap[badge.id] ?? 0;

          return BadgeWidget(
            badge: badge,
            currentProgress: progress,
            onTap: () {
              // Show badge detail dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      Text(badge.icon, style: TextStyle(fontSize: 32)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          badge.name,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(badge.description),
                      SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (progress / badge.requirementCount).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          badge.isUnlocked ? Colors.green : Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        badge.isUnlocked
                            ? '✅ Unlocked on ${badge.unlockedAt?.toString().split(' ')[0]}'
                            : 'Progress: $progress/${badge.requirementCount}',
                        style: TextStyle(
                          fontSize: 13,
                          color: badge.isUnlocked ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
