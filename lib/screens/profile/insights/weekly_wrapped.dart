import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../../../services/metrics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeeklyWrappedScreen extends StatefulWidget {
  const WeeklyWrappedScreen({super.key});

  @override
  State<WeeklyWrappedScreen> createState() => _WeeklyWrappedScreenState();
}

class _WeeklyWrappedScreenState extends State<WeeklyWrappedScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Map<String, String> _moodEmojis = {
    'Happy': '😊',
    'Angry': '😠',
    'Sad': '😔',
    'Natural': '😐',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    ));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: MetricsService.getMoodHistoryStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
          }

          final history = snapshot.data!;
          final now = DateTime.now();
          final weeklyHistory = history.where((m) {
            final ts = m['timestamp'] as Timestamp?;
            if (ts == null) return false;
            return now.difference(ts.toDate()).inDays < 7;
          }).toList();

          if (weeklyHistory.isEmpty) {
            return Scaffold(
              backgroundColor: AppTheme.backgroundDark,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: const Center(
                child: Text(
                  'Not enough data for this week yet!',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ),
            );
          }

          // Compute top mood
          Map<String, int> counts = {};
          for (var m in weeklyHistory) {
            final mood = m['mood'] as String;
            counts[mood] = (counts[mood] ?? 0) + 1;
          }

          String topMood = counts.keys.first;
          int maxCount = counts.values.first;

          counts.forEach((mood, count) {
            if (count > maxCount) {
              maxCount = count;
              topMood = mood;
            }
          });

          return Stack(
            children: [
              // Dynamic Background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.moodColors[topMood]?.withValues(alpha: 0.4) ?? Theme.of(context).primaryColor.withValues(alpha: 0.4),
                      AppTheme.backgroundDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Weekly Wrapped',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This week, your reigning vibe was...',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(
                                    _moodEmojis[topMood] ?? '✨',
                                    style: const TextStyle(fontSize: 64),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    topMood.toUpperCase(),
                                    style: TextStyle(
                                      color: AppTheme.moodColors[topMood] ?? Theme.of(context).primaryColor,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'You checked in ${weeklyHistory.length} times this week.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 48),
                              
                              // Visual bar graph for mood distribution
                              const Text(
                                'MOOD BREAKDOWN',
                                style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: _moodEmojis.keys.map((mood) {
                                  final count = counts[mood] ?? 0;
                                  final percentage = count / weeklyHistory.length;
                                  if (percentage == 0) return const SizedBox.shrink();
                                  
                                  return Expanded(
                                    flex: (percentage * 100).toInt(),
                                    child: Container(
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.moodColors[mood] ?? Colors.grey,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: counts.entries
                                    .where((e) => e.value > 0)
                                    .map((e) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                            color: AppTheme.moodColors[e.key] ?? Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${e.key} ${(e.value / weeklyHistory.length * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
