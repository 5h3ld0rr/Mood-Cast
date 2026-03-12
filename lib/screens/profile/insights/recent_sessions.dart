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
                final dateStr = ts != null ? DateFormat('MMM dd, hh:mm a').format(ts.toDate()) : 'Recent';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSessionTile(
                    context,
                    mood,
                    dateStr,
                    moodEmojis[mood] ?? '👤',
                    moodColors[mood] ?? Colors.white,
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2)),
        ],
      ),
    );
  }
}
