import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme.dart';
import '../../../services/metrics_service.dart';
import 'package:intl/intl.dart';
import 'recent_sessions.dart';
import '../../../services/database_service.dart';
import '../../../services/player_service.dart';
import '../../../widgets/cached_image.dart';
import 'dart:ui' as ui;

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final Map<String, String> _moodEmojis = {
    'Happy': '😊',
    'Angry': '😠',
    'Sad': '😔',
    'Natural': '😐',
  };

  Map<String, dynamic> _calculateStats(
    List<Map<String, dynamic>> history,
    String range,
  ) {
    if (history.isEmpty) {
      return {
        'positive': '0%',
        'breakdown': <String, int>{'Natural': 0},
        'avg': '0.0',
        'bars': List.generate(7, (_) => {'intensity': 0.05, 'mood': 'Natural'}),
        'recent': <Map<String, dynamic>>[],
      };
    }

    final now = DateTime.now();
    List<Map<String, dynamic>> filtered = history;

    if (range == 'Day') {
      filtered = history.where((m) {
        final ts = m['timestamp'] as Timestamp?;
        if (ts == null) return false;
        return now.difference(ts.toDate()).inHours < 24;
      }).toList();
    } else if (range == 'Week') {
      filtered = history.where((m) {
        final ts = m['timestamp'] as Timestamp?;
        if (ts == null) return false;
        return now.difference(ts.toDate()).inDays < 7;
      }).toList();
    }

    if (filtered.isEmpty) filtered = history.take(10).toList();

    // Mood Breakdown
    Map<String, int> counts = {};
    for (var m in filtered) {
      final mood = m['mood'] as String;
      counts[mood] = (counts[mood] ?? 0) + 1;
    }

    int total = filtered.length;
    int positiveCount = (counts['Happy'] ?? 0);
    String positivePercent = total > 0
        ? '${((positiveCount / total) * 100).toInt()}%'
        : '0%';

    // Intensity calculation
    double sumIntensity = 0;
    for (var m in filtered) {
      final mood = m['mood'];
      if (mood == 'Happy') {
        sumIntensity += 0.9;
      } else if (mood == 'Natural') {
        sumIntensity += 0.6;
      } else if (mood == 'Angry') {
        sumIntensity += 0.8;
      } else if (mood == 'Sad') {
        sumIntensity += 0.3;
      }
    }
    double avg = total > 0 ? sumIntensity / total : 0.0;

    int blocksCount = 7;
    if (range == 'Month') {
      blocksCount = 30;
    } else if (range == 'Day') {
      blocksCount = 24;
    }

    List<Map<String, dynamic>> bars = List.generate(blocksCount, (index) {
      if (range == 'Day') {
        final hour = now.subtract(Duration(hours: 23 - index));
        final hourMoods = history.where((m) {
          final ts = m['timestamp'] as Timestamp?;
          if (ts == null) return false;
          final date = ts.toDate();
          return date.year == hour.year &&
              date.month == hour.month &&
              date.day == hour.day &&
              date.hour == hour.hour;
        }).toList();

        double intensity = 0.05;
        String dominantMood = 'Natural';
        if (hourMoods.isNotEmpty) {
          double dSum = 0;
          Map<String, int> localCounts = {};
          for (var m in hourMoods) {
            final mood = m['mood'];
            localCounts[mood] = (localCounts[mood] ?? 0) + 1;
            if (mood == 'Happy') {
              dSum += 0.9;
            } else if (mood == 'Natural')
              dSum += 0.6;
            else if (mood == 'Angry')
              dSum += 0.8;
            else if (mood == 'Sad')
              dSum += 0.3;
          }
          intensity = (dSum / hourMoods.length).clamp(0.05, 1.0);
          dominantMood = localCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
        return {'intensity': intensity, 'mood': dominantMood};
      } else {
        final day = now.subtract(Duration(days: blocksCount - 1 - index));
        final dayMoods = history.where((m) {
          final ts = m['timestamp'] as Timestamp?;
          if (ts == null) return false;
          final date = ts.toDate();
          return date.year == day.year &&
              date.month == day.month &&
              date.day == day.day;
        }).toList();

        double intensity = 0.05;
        String dominantMood = 'Natural';
        if (dayMoods.isNotEmpty) {
          double dSum = 0;
          Map<String, int> localCounts = {};
          for (var m in dayMoods) {
            final mood = m['mood'];
            localCounts[mood] = (localCounts[mood] ?? 0) + 1;
            if (mood == 'Happy') {
              dSum += 0.9;
            } else if (mood == 'Natural')
              dSum += 0.6;
            else if (mood == 'Angry')
              dSum += 0.8;
            else if (mood == 'Sad')
              dSum += 0.3;
          }
          intensity = (dSum / dayMoods.length).clamp(0.05, 1.0);
          dominantMood = localCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
        return {'intensity': intensity, 'mood': dominantMood};
      }
    });

    // Time of day pattern
    Map<String, Map<String, int>> timeOfDayCounts = {
      'Morning': {},
      'Afternoon': {},
      'Evening': {},
      'Night': {},
    };

    for (var m in filtered) {
       final ts = m['timestamp'] as Timestamp?;
       if (ts == null) continue;
       final hour = ts.toDate().hour;
       String tod;
       if (hour >= 5 && hour < 12) tod = 'Morning';
       else if (hour >= 12 && hour < 17) tod = 'Afternoon';
       else if (hour >= 17 && hour < 21) tod = 'Evening';
       else tod = 'Night';

       final mood = m['mood'] as String;
       timeOfDayCounts[tod]![mood] = (timeOfDayCounts[tod]![mood] ?? 0) + 1;
    }

    Map<String, String> actionableInsights = {};
    if (filtered.isNotEmpty) {
      int maxHappy = -1;
      String happyTod = '';
      int maxSad = -1;
      String sadTod = '';
      
      timeOfDayCounts.forEach((tod, moods) {
        int h = moods['Happy'] ?? 0;
        if (h > maxHappy) {
          maxHappy = h;
          happyTod = tod;
        }
        int s = moods['Sad'] ?? 0;
        if (s > maxSad) {
          maxSad = s;
          sadTod = tod;
        }
      });
      
      if (maxHappy > 0) {
        actionableInsights['Peak Positivity'] = 'You usually feel great in the $happyTod.';
      }
      if (maxSad > 0) {
        actionableInsights['Needs a Boost'] = 'You tend to feel down in the $sadTod. Try listening to upbeat music then!';
      }
      if (actionableInsights.isEmpty && counts.isNotEmpty) {
        // Fallback
        actionableInsights['Mood Pattern'] = 'Your mood remains relatively stable throughout the day.';
      }
    }

    return {
      'positive': positivePercent,
      'breakdown': counts,
      'avg': (avg * 10).toStringAsFixed(1),
      'bars': bars,
      'recent': history.take(5).toList(),
      'actionableInsights': actionableInsights,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: MetricsService.getMoodHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final history = snapshot.data ?? [];

        return DefaultTabController(
          length: 3,
          initialIndex: 1,
          child: Scaffold(
            backgroundColor: Theme.of(context).canvasColor,
            body: Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.5],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Text(
                              'Trends & Insights',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.textMuted,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Day', height: 40),
                            Tab(text: 'Week', height: 40),
                            Tab(text: 'Month', height: 40),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildInsightsContent(history, 'Day'),
                            _buildInsightsContent(history, 'Week'),
                            _buildInsightsContent(history, 'Month'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightsContent(
    List<Map<String, dynamic>> history,
    String tabType,
  ) {
    final stats = _calculateStats(history, tabType);
    final breakdown = stats['breakdown'] as Map<String, int>;
    int totalMoods = breakdown.values.fold(0, (sum, count) => sum + count);

    String topMood = 'None';
    if (breakdown.isNotEmpty) {
      topMood = breakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    final topMoodColor =
        AppTheme.moodColors[topMood] ?? Theme.of(context).primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood Breakdown',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0.0,
                            end: (double.tryParse(
                                      stats['positive'].replaceAll('%', ''),
                                    ) ??
                                    0.0) /
                                100,
                          ),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) {
                            return SizedBox(
                              width: 130,
                              height: 130,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 10,
                                    valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.02)),
                                  ),
                                  CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 10,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation(topMoodColor),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Column(
                          children: [
                            Text(
                              stats['positive'],
                              style: TextStyle(
                                color: topMoodColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: topMoodColor.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'POSITIVE',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dominant Mood',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topMood,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: topMoodColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: topMoodColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Highest records: ${breakdown[topMood] ?? 0}',
                            style: TextStyle(
                              color: topMoodColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Column(
                  children: breakdown.keys.map((mood) {
                    final count = breakdown[mood] ?? 0;
                    final percentage = totalMoods > 0
                        ? (count / totalMoods)
                        : 0.0;
                    final moodColor =
                        AppTheme.moodColors[mood] ??
                        Theme.of(context).primaryColor;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: moodColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: moodColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 70,
                            child: Text(
                              mood,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.05,
                                ),
                                valueColor: AlwaysStoppedAnimation(moodColor),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 30,
                            child: Text(
                              count.toString(),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Emotional Intensity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Avg: ${stats['avg']}/10',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: _buildHeatmap(stats['bars'] as List<Map<String, dynamic>>, context),
            ),
          ),
          const SizedBox(height: 32),
          
          if ((stats['actionableInsights'] as Map<String, String>).isNotEmpty) ...[
            const Text(
              'Habits & Triggers',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(stats['actionableInsights'] as Map<String, String>).entries.map((entry) {
              return _buildGlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor,
                child: Row(
                  children: [
                    Icon(
                      entry.key.contains('Boost') ? Icons.bolt : Icons.auto_awesome,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
          
          const Text(
             'Your Music Triggers',
             style: TextStyle(
               color: Colors.white,
               fontSize: 18,
               fontWeight: FontWeight.bold,
             ),
          ),
          const SizedBox(height: 16),
          _buildMusicHabits(context),
          const SizedBox(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecentSessionsScreen(),
                    ),
                  );
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(stats['recent'] as List).map((m) {
            final mood = m['mood'] as String;
            final ts = m['timestamp'] as Timestamp?;
            final dateStr = ts != null
                ? DateFormat('MMM dd, hh:mm a').format(ts.toDate())
                : 'Recent';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSessionTile(
                mood,
                dateStr,
                _moodEmojis[mood] ?? '✨',
                AppTheme.moodColors[mood] ?? Theme.of(context).primaryColor,
              ),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMusicHabits(BuildContext context) {
    return StreamBuilder<List<SongInfo>>(
      stream: DatabaseService().getRecentTracks(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final songs = snapshot.data ?? [];
        if (songs.isEmpty) {
          return _buildGlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 16.0,
            child: const Center(
              child: Text(
                'Listen to more music to see your top triggers here.',
                style: TextStyle(color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children: songs.map((song) {
            return _buildGlassCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              borderRadius: 16.0,
              child: Row(
                children: [
                    CachedImage(
                      imageUrl: song.coverUrl,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                       Icons.graphic_eq,
                       color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                       size: 20,
                    ),
                  ],
                ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHeatmap(List<Map<String, dynamic>> data, BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Wrap(
        spacing: 5.0,
        runSpacing: 5.0,
        alignment: WrapAlignment.center,
        children: data.map((item) {
           final intensity = item['intensity'] as double;
           final mood = item['mood'] as String;
           final color = AppTheme.moodColors[mood] ?? Theme.of(context).primaryColor;
           
           return Tooltip(
             message: '$mood Intensity: ${(intensity * 10).toStringAsFixed(1)}',
             child: AnimatedContainer(
               duration: const Duration(milliseconds: 300),
               width: 20,
               height: 20,
               decoration: BoxDecoration(
                 color: intensity <= 0.05 
                     ? Colors.white.withValues(alpha: 0.05) 
                     : color.withValues(alpha: intensity.clamp(0.3, 1.0)),
                 borderRadius: BorderRadius.circular(4),
                 border: Border.all(
                   color: intensity <= 0.05 
                       ? Colors.white.withValues(alpha: 0.1) 
                       : color.withValues(alpha: 0.2),
                   width: 1,
                 ),
               ),
             ),
           );
        }).toList(),
      ),
    );
  }

  Widget _buildSessionTile(
    String title,
    String subtitle,
    String emoji,
    Color color,
  ) {
    return _buildGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 16.0,
      color: color,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    double borderRadius = 24.0,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color?.withValues(alpha: 0.1) ?? Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color?.withValues(alpha: 0.05) ?? Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: color?.withValues(alpha: 0.1) ?? Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
