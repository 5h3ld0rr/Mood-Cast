import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../theme.dart';
import '../../../services/metrics_service.dart';

class RecentSessionsScreen extends StatelessWidget {
  const RecentSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> moodEmojis = {
      'Happy': '😊',
      'Angry': '😠',
      'Sad': '😔',
      'Natural': '😐',
    };

    final Map<String, Color> moodColors = {
      'Happy': Colors.purpleAccent,
      'Angry': Colors.redAccent,
      'Sad': Colors.blueAccent,
      'Natural': Theme.of(context).primaryColor,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: const Text(
          'Recent History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: MetricsService.getMoodHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(
              child: Text(
                'No scans yet',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            );
          }

          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final mood = entry['mood'] as String;
                final ts = entry['timestamp'] as Timestamp?;
                final dateStr = ts != null
                    ? DateFormat('MMM dd, hh:mm a').format(ts.toDate())
                    : 'Recent';

                final confidence = entry['confidence'] as Map<String, dynamic>?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSessionTile(
                    context,
                    mood,
                    dateStr,
                    moodEmojis[mood] ?? '👤',
                    moodColors[mood] ?? Colors.white,
                    confidence,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionTile(
    BuildContext context,
    String title,
    String subtitle,
    String emoji,
    Color color,
    Map<String, dynamic>? confidence,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
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
          if (confidence != null && confidence.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: confidence.entries
                  .where((e) => (e.value as num) > 0.05)
                  .map((e) {
                final score = (e.value as num).toDouble();
                final moodName = e.key;
                final moodColor = AppTheme.moodColors[moodName] ?? Colors.white54;
                
                return Column(
                  children: [
                    Text(
                      '${(score * 100).toInt()}%',
                      style: TextStyle(
                        color: moodColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      moodName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
