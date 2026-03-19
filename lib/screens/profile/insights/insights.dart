import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme.dart';
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
    if (range == 'Month') blocksCount = 30;
    else if (range == 'Day') blocksCount = 24;

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
            if (mood == 'Happy') dSum += 0.9;
            else if (mood == 'Natural') dSum += 0.6;
            else if (mood == 'Angry') dSum += 0.8;
            else if (mood == 'Sad') dSum += 0.3;
          }
          intensity = (dSum / hourMoods.length).clamp(0.05, 1.0);
          dominantMood = localCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
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
            if (mood == 'Happy') dSum += 0.9;
            else if (mood == 'Natural') dSum += 0.6;
            else if (mood == 'Angry') dSum += 0.8;
            else if (mood == 'Sad') dSum += 0.3;
          }
          intensity = (dSum / dayMoods.length).clamp(0.05, 1.0);
          dominantMood = localCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        }
        return {'intensity': intensity, 'mood': dominantMood};
      }
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
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.4), blurRadius: 10)
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.textMuted,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
      topMood = breakdown.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    final topMoodColor = AppTheme.moodColors[topMood] ?? Theme.of(context).primaryColor;

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
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: double.tryParse(stats['positive'].replaceAll('%', ''))! / 100,
                            strokeWidth: 10,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation(topMoodColor),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              stats['positive'],
                              style: TextStyle(
                                color: topMoodColor,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'POSITIVE',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 9,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dominant Mood', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: topMoodColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: topMoodColor.withValues(alpha: 0.3)),
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
                    final percentage = totalMoods > 0 ? (count / totalMoods) : 0.0;
                    final moodColor = AppTheme.moodColors[mood] ?? Theme.of(context).primaryColor;
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
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
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
          Container(
            height: 180,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: CustomPaint(
                painter: _SplineChartPainter(
                  stats['bars'] as List<Map<String, dynamic>>,
                  Theme.of(context).primaryColor,
                ),
              ),
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



  Widget _buildSessionTile(
    String title,
    String subtitle,
    String emoji,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        ),
      ),
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
}

class _SplineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final Color baseColor;

  _SplineChartPainter(this.data, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final widthStep = size.width / (data.length - 1 == 0 ? 1 : data.length - 1);
    
    // Normalizing values
    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
        final x = i * widthStep;
        final intensity = data[i]['intensity'] as double;
        // Invert Y so 1.0 is at top (0.0 height) and 0.0 is at bottom (size.height)
        final y = size.height - (intensity * size.height);
        points.add(Offset(x, y));
    }

    if (points.length == 1) {
       canvas.drawCircle(points[0], 4, paint..style=PaintingStyle.fill);
       return;
    }

    path.moveTo(points[0].dx, points[0].dy);
    
    // Smooth bezier curve calculation
    for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        
        path.cubicTo(
           controlPoint1.dx, controlPoint1.dy,
           controlPoint2.dx, controlPoint2.dy,
           p1.dx, p1.dy
        );
    }

    // Draw the Gradient Area below the curve
    final areaPath = Path.from(path);
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.lineTo(points.first.dx, size.height);
    areaPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          baseColor.withValues(alpha: 0.6),
          baseColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(areaPath, gradientPaint);

    // Draw the Line itself
    canvas.drawPath(path, paint);
    
    // Draw tiny glowing dots on nodes
    final dotPaint = Paint()..color = Colors.white;
    for (var point in points) {
       canvas.drawCircle(point, 6, Paint()..color=baseColor.withValues(alpha:0.3)..style=PaintingStyle.fill);
       canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
