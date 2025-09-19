import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/streak_service.dart';
import '../../utils/app_theme.dart';
import '../../models/badge_model.dart';

class StreakAndBadgesPage extends StatefulWidget {
  static const routeName = '/streak-and-badges';
  
  const StreakAndBadgesPage({super.key});

  @override
  State<StreakAndBadgesPage> createState() => _StreakAndBadgesPageState();
}

class _StreakAndBadgesPageState extends State<StreakAndBadgesPage> {
  @override
  void initState() {
    super.initState();
    // Ensure data is loaded when page opens
    Future.microtask(() {
      final streakService = Provider.of<StreakService>(context, listen: false);
      streakService.recordEnergySavingAction(); // Optional: record visit as action
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StreakService>(
      builder: (context, streakService, child) {
        final streak = streakService.currentStreak;
        final nextMilestone = streakService.getNextMilestone(streak);
        final progress = streakService.getProgressToNextMilestone(streak);
        final badges = streakService.badges;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text("Energy Saver Progress"),
            backgroundColor: AppTheme.primaryColor,
          ),
          body: Column(
            children: [
              // Streak display + progress bar
              _buildStreakProgressSection(streak, nextMilestone, progress),
              
              // Divider
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              ),
              
              // Badges header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      "Your Energy Saving Badges",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Badge grid
              Expanded(
                child: _buildBadgeGrid(badges),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakProgressSection(int streak, int nextMilestone, double progress) {
    // Determine progress color based on percentage
    Color progressColor;
    if (progress < 0.3) {
      progressColor = Colors.red;
    } else if (progress < 0.7) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            "YOUR SAVING STREAK",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$streak DAYS",
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress bar with rounded corners
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          Text(
            "$streak / $nextMilestone days for next badge",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Quick actions
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.flash_on),
            label: const Text("I Saved Energy Today!"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              Provider.of<StreakService>(context, listen: false).recordEnergySavingAction()
                .then((success) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Great job! Your streak continues!"),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  }
                });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid(List<BadgeModel> badges) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No badges yet – keep saving energy!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        
        return GestureDetector(
          onTap: () {
            if (badge.isUnlocked) {
              _showBadgeDetails(context, badge);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Keep saving energy to unlock this badge!"),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: badge.isUnlocked
                  ? Border.all(color: AppTheme.primaryColor, width: 2)
                  : null,
            ),
            child: Opacity(
              opacity: badge.isUnlocked ? 1.0 : 0.3,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Image.asset(
                        badge.iconPath,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.emoji_events,
                            size: 40,
                            color: badge.isUnlocked ? AppTheme.primaryColor : Colors.grey,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge.title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (badge.isUnlocked && badge.unlockedAt != null)
                      Text(
                        "Earned ${_formatDate(badge.unlockedAt!)}",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showBadgeDetails(BuildContext context, BadgeModel badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(badge.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              badge.iconPath,
              height: 80,
              width: 80,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.emoji_events,
                  size: 80,
                  color: AppTheme.primaryColor,
                );
              },
            ),
            const SizedBox(height: 16),
            Text(badge.description),
            const SizedBox(height: 8),
            if (badge.unlockedAt != null)
              Text(
                "Earned on ${_formatDate(badge.unlockedAt!)}",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Could add sharing functionality here
            },
            child: const Text("Share"),
          ),
        ],
      ),
    );
  }
}