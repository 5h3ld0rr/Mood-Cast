import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/metrics_service.dart';
import 'package:intl/intl.dart';
import 'recent_sessions.dart';

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
        'breakdown': {'Natural': 100},
        'avg': '0.0',
        'bars': List.generate(7, (_) => 0.1),
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
      } else if (mood == 'Natural')
        sumIntensity += 0.6;
      else if (mood == 'Angry')
        sumIntensity += 0.8;
      else if (mood == 'Sad')
        sumIntensity += 0.3;
    }
    double avg = total > 0 ? sumIntensity / total : 0.0;

    // Last 7 days intensity bars
    List<double> bars = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final dayMoods = history.where((m) {
        final ts = m['timestamp'] as Timestamp?;
        if (ts == null) return false;
        final date = ts.toDate();
        return date.year == day.year &&
            date.month == day.month &&
            date.day == day.day;
      }).toList();

      if (dayMoods.isEmpty) return 0.1;
      double dSum = 0;
      for (var m in dayMoods) {
        final mood = m['mood'];
        if (mood == 'Happy') {
          dSum += 0.9;
        } else if (mood == 'Natural')
          dSum += 0.6;
        else if (mood == 'Angry')
          dSum += 0.8;
        else if (mood == 'Sad')
          dSum += 0.3;
      }
      return (dSum / dayMoods.length).clamp(0.1, 1.0);
    });

    return {
      'positive': positivePercent,
      'breakdown': counts,
      'avg': (avg * 10).toStringAsFixed(1),
      'bars': bars,
      'recent': history.take(5).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> _moodColors = {
      'Happy': Colors.tealAccent,
      'Angry': Colors.redAccent,
      'Sad': Colors.blueAccent,
      'Natural': Theme.of(context).primaryColor,
    };

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: MetricsService.getMoodHistoryStream(),
      builder: (context, snapshot) {
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0xFF1A3A5F), Colors.transparent],
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
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: TabBar(
                          indicatorColor: Theme.of(context).primaryColor,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Day'),
                            Tab(text: 'Week'),
                            Tab(text: 'Month'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildInsightsContent(history, 'Day', _moodColors),
                            _buildInsightsContent(history, 'Week', _moodColors),
                            _buildInsightsContent(
                              history,
                              'Month',
                              _moodColors,
                            ),
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
    Map<String, Color> moodColors,
  ) {
    final stats = _calculateStats(history, tabType);
    final breakdown = stats['breakdown'] as Map<String, int>;

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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value:
                            double.tryParse(
                              stats['positive'].replaceAll('%', ''),
                            )! /
                            100,
                        strokeWidth: 12,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: const AlwaysStoppedAnimation(
                          Colors.tealAccent,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          stats['positive'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'POSITIVE',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  children: _moodEmojis.keys.map((mood) {
                    final count = breakdown[mood] ?? 0;
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 100) / 2,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: moodColors[mood],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mood,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            count.toString(),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
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
          Container(
            height: 160,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: (stats['bars'] as List<double>)
                  .map((val) => _buildBar(val))
                  .toList(),
            ),
          ),
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
                _moodEmojis[mood]!,
                moodColors[mood]!,
              ),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor) {
    return Container(
      width: 14,
      height: 100 * heightFactor,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.3),
            Theme.of(context).primaryColor,
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSessionTile(
    String title,
    String subtitle,
    String emoji,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2)),
        ],
      ),
    );
  }
}
