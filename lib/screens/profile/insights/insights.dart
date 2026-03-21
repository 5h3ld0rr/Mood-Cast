import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme.dart';
import '../../../services/metrics_service.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../services/player_service.dart';
import '../../../widgets/cached_image.dart';
import 'dart:ui' as ui;

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<List<Map<String, dynamic>>> _historyStream;
  late Stream<List<SongInfo>> _musicHabitsStream;
  late ValueNotifier<String> _rangeNotifier;

  final Map<String, String> _moodEmojis = {
    'Happy': '😊',
    'Angry': '😠',
    'Sad': '😔',
    'Natural': '😐',
  };

  final String _selectedRange = 'Week';
  late final ValueNotifier<int> _yearNotifier;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _historyStream = MetricsService.getMoodHistoryStream();
    _musicHabitsStream = DatabaseService().getTopTracks(limit: 5);
    _rangeNotifier = ValueNotifier<String>(_selectedRange);
    _yearNotifier = ValueNotifier<int>(DateTime.now().year);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        return;
      }
      if (_tabController.index == 0) {
        _rangeNotifier.value = 'Day';
      } else if (_tabController.index == 1) {
        _rangeNotifier.value = 'Week';
      } else {
        _rangeNotifier.value = 'Month';
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rangeNotifier.dispose();
    _yearNotifier.dispose();
    super.dispose();
  }

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
        'actionableInsights': <String, String>{},
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

    int blocksCount = 7;
    if (range == 'Month') {
      blocksCount = 30;
    } else if (range == 'Day') {
      blocksCount = 24;
    }

    if (filtered.isEmpty) {
      return {
        'positive': '0%',
        'breakdown': <String, int>{'Natural': 0},
        'avg': '0.0',
        'bars': List.generate(
          blocksCount,
          (_) => {'intensity': 0.05, 'mood': 'Natural'},
        ),
        'recent': history.take(5).toList(),
        'actionableInsights': <String, String>{
          'Not enough data':
              'No moods detected for this time range. Keep listening!',
        },
      };
    }
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
            } else if (mood == 'Natural') {
              dSum += 0.6;
            } else if (mood == 'Angry') {
              dSum += 0.8;
            } else if (mood == 'Sad') {
              dSum += 0.3;
            }
          }
          intensity = (dSum / hourMoods.length).clamp(0.05, 1.0);
          dominantMood = localCounts.entries
              .reduce(
                (entry1, entry2) =>
                    entry1.value > entry2.value ? entry1 : entry2,
              )
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
            } else if (mood == 'Natural') {
              dSum += 0.6;
            } else if (mood == 'Angry') {
              dSum += 0.8;
            } else if (mood == 'Sad') {
              dSum += 0.3;
            }
          }
          intensity = (dSum / dayMoods.length).clamp(0.05, 1.0);
          dominantMood = localCounts.entries
              .reduce(
                (entry1, entry2) =>
                    entry1.value > entry2.value ? entry1 : entry2,
              )
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
      if (hour >= 5 && hour < 12) {
        tod = 'Morning';
      } else if (hour >= 12 && hour < 17) {
        tod = 'Afternoon';
      } else if (hour >= 17 && hour < 21) {
        tod = 'Evening';
      } else {
        tod = 'Night';
      }

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
        actionableInsights['Peak Positivity'] =
            'You usually feel great in the $happyTod.';
      }
      if (maxSad > 0) {
        actionableInsights['Needs a Boost'] =
            'You tend to feel down in the $sadTod. Try listening to upbeat music then!';
      }
      if (actionableInsights.isEmpty && counts.isNotEmpty) {
        // Fallback
        actionableInsights['Mood Pattern'] =
            'Your mood remains relatively stable throughout the day.';
      }
    }

    return {
      'positive': positivePercent,
      'breakdown': counts,
      'avg': (avg * 10).toStringAsFixed(1),
      'bars': bars,
      'actionableInsights': actionableInsights,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final history = snapshot.data ?? [];

        return Scaffold(
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

                    Expanded(child: _buildInsightsContent(history)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightsContent(List<Map<String, dynamic>> history) {
    final availableYears =
        history
            .map((m) => (m['timestamp'] as Timestamp?)?.toDate().year)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (availableYears.isEmpty) {
      availableYears.add(DateTime.now().year);
    }

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
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TabBar(
              controller: _tabController,
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
          SizedBox(
            height: 380,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMoodBreakdownCard(history, 'Day'),
                _buildMoodBreakdownCard(history, 'Week'),
                _buildMoodBreakdownCard(history, 'Month'),
              ],
            ),
          ),

          ValueListenableBuilder<String>(
            valueListenable: _rangeNotifier,
            builder: (context, currentRange, _) {
              final stats = _calculateStats(history, currentRange);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  ValueListenableBuilder<int>(
                    valueListenable: _yearNotifier,
                    builder: (context, currentYear, _) {
                      if (!availableYears.contains(currentYear)) {
                        Future.microtask(
                          () => _yearNotifier.value = availableYears.first,
                        );
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Yearly Heatmap',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              DropdownButton<int>(
                                value: currentYear,
                                dropdownColor: const Color(0xFF1E1E2C),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                underline: const SizedBox(),
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Theme.of(context).primaryColor,
                                ),
                                items: availableYears.map((year) {
                                  return DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) _yearNotifier.value = val;
                                },
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
                              child: _buildHeatmap(
                                history,
                                context,
                                currentYear,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  if ((stats['actionableInsights'] as Map<String, String>)
                      .isNotEmpty) ...[
                    const Text(
                      'Habits & Triggers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...(stats['actionableInsights'] as Map<String, String>)
                        .entries
                        .map((entry) {
                          return _buildGlassCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            color: Theme.of(context).primaryColor,
                            child: Row(
                              children: [
                                Icon(
                                  entry.key.contains('Boost')
                                      ? Icons.bolt
                                      : Icons.auto_awesome,
                                  color: Theme.of(context).primaryColor,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          const Text(
            'Most Listened Tracks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMusicHabits(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMusicHabits(BuildContext context) {
    return StreamBuilder<List<SongInfo>>(
      stream: _musicHabitsStream,
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
                'Keep streaming to discover your most played songs!',
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
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.5),
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

  Widget _buildHeatmap(
    List<Map<String, dynamic>> history,
    BuildContext context,
    int targetYear,
  ) {
    if (history.isEmpty) return const SizedBox.shrink();

    final firstDay = DateTime(targetYear, 1, 1);
    final lastDay = DateTime(targetYear, 12, 31);

    final startDate = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    final endDate = lastDay.add(Duration(days: 7 - lastDay.weekday));

    final totalDays = endDate.difference(startDate).inDays + 1;
    final totalWeeks = totalDays ~/ 7;

    Map<DateTime, List<Map<String, dynamic>>> group = {};
    for (var m in history) {
      final ts = m['timestamp'] as Timestamp?;
      if (ts == null) continue;
      final d = ts.toDate();
      if (d.year != targetYear) continue;
      final date = DateTime(d.year, d.month, d.day);
      group.putIfAbsent(date, () => []).add(m);
    }

    List<Widget> columns = [];

    for (int w = 0; w < totalWeeks; w++) {
      List<Widget> dayWidgets = [];

      bool isFirstOfMonth = false;
      String monthName = '';

      for (int i = 0; i < 7; i++) {
        final currentDay = startDate.add(Duration(days: w * 7 + i));

        if (currentDay.year == targetYear && currentDay.day == 1) {
          isFirstOfMonth = true;
          monthName = DateFormat('MMM').format(currentDay);
        }

        if (currentDay.year != targetYear) {
          dayWidgets.add(const SizedBox(width: 14, height: 14));
          continue;
        }

        final dayMoods = group[currentDay] ?? [];
        double intensity = 0.05;
        String dominantMood = 'Natural';

        if (dayMoods.isNotEmpty) {
          double dSum = 0;
          Map<String, int> localCounts = {};
          for (var m in dayMoods) {
            final mood = m['mood'] as String;
            localCounts[mood] = (localCounts[mood] ?? 0) + 1;
            if (mood == 'Happy') {
              dSum += 0.9;
            } else if (mood == 'Natural') {
              dSum += 0.6;
            } else if (mood == 'Angry') {
              dSum += 0.8;
            } else if (mood == 'Sad') {
              dSum += 0.3;
            }
          }
          intensity = (dSum / dayMoods.length).clamp(0.05, 1.0);
          dominantMood = localCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }

        final color =
            AppTheme.moodColors[dominantMood] ?? Theme.of(context).primaryColor;

        dayWidgets.add(
          GestureDetector(
            onTap: () {
              if (dayMoods.isNotEmpty) {
                _showDayDetailReport(context, currentDay, dayMoods);
              }
            },
            child: Tooltip(
              message:
                  '${DateFormat('MMM dd, yyyy').format(currentDay)}\n${dayMoods.isEmpty ? "No data" : "$dominantMood: ${(intensity * 10).toStringAsFixed(1)}/10"}\nTap for details',
              triggerMode: TooltipTriggerMode.longPress,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 14,
                height: 14,
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
            ),
          ),
        );
      }

      columns.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
                width: 14,
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  maxWidth: 40,
                  child: Text(
                    isFirstOfMonth ? monthName : '',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
              ...dayWidgets.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: w,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildDayLabel('Mon'),
              const SizedBox(height: 18),
              _buildDayLabel('Wed'),
              const SizedBox(height: 18),
              _buildDayLabel('Fri'),
            ],
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 155,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: columns,
            ),
          ),
        ),
      ],
    );
  }

  void _showDayDetailReport(
    BuildContext context,
    DateTime date,
    List<Map<String, dynamic>> dayMoods,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161621),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(date),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${dayMoods.length} entries',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Mood Timeline',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    // Changed from Flexible to Expanded for DraggableScrollableSheet
                    child: ListView.builder(
                      controller: scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: dayMoods.length,
                      itemBuilder: (context, index) {
                        final mood = dayMoods[index];
                        final moodName = mood['mood'] as String;
                        final ts = mood['timestamp'] as Timestamp;
                        final timeStr = DateFormat(
                          'hh:mm a',
                        ).format(ts.toDate());
                        final color =
                            AppTheme.moodColors[moodName] ??
                            Theme.of(context).primaryColor;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              SizedBox(
                                // Changed from Container to SizedBox for explicit width
                                width: 50,
                                child: Text(
                                  timeStr,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 40,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [color, color.withValues(alpha: 0)],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _buildGlassCard(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  borderRadius: 16,
                                  child: Row(
                                    children: [
                                      Text(
                                        _moodEmojis[moodName] ?? '✨',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        moodName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (mood.containsKey('intensity'))
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'Intensity ${mood['intensity']}',
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayLabel(String text) {
    return SizedBox(
      height: 18,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildMoodBreakdownCard(
    List<Map<String, dynamic>> history,
    String range,
  ) {
    final stats = _calculateStats(history, range);
    final breakdown = stats['breakdown'] as Map<String, int>;
    int totalMoodsCount = breakdown.values.fold(
      0,
      (previousValue, element) => previousValue + element,
    );

    String topMood = 'None';
    if (breakdown.isNotEmpty) {
      topMood = breakdown.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    final topMoodColor =
        AppTheme.moodColors[topMood] ?? Theme.of(context).primaryColor;

    return _buildGlassCard(
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
                      end:
                          (double.tryParse(
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
                              valueColor: AlwaysStoppedAnimation(
                                Colors.white.withValues(alpha: 0.02),
                              ),
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
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
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
              final percentage = totalMoodsCount > 0
                  ? (count / totalMoodsCount)
                  : 0.0;
              final moodColor =
                  AppTheme.moodColors[mood] ?? Theme.of(context).primaryColor;
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
            color:
                color?.withValues(alpha: 0.1) ??
                Colors.black.withValues(alpha: 0.1),
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
              color:
                  color?.withValues(alpha: 0.05) ??
                  Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color:
                    color?.withValues(alpha: 0.1) ??
                    Colors.white.withValues(alpha: 0.08),
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
