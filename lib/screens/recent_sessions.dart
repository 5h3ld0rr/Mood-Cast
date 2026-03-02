import 'package:flutter/material.dart';
import '../theme.dart';

class RecentSessionsScreen extends StatelessWidget {
  const RecentSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        title: const Text(
          'Recent Sessions',
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSessionTile(
              'Deep Relaxation',
              'Today • 10:30 AM',
              '15m',
              Icons.sentiment_very_satisfied,
              Colors.tealAccent,
            ),
            const SizedBox(height: 12),
            _buildSessionTile(
              'Morning Flow',
              'Yesterday • 08:15 AM',
              '20m',
              Icons.self_improvement,
              AppTheme.primary,
            ),
            const SizedBox(height: 12),
            _buildSessionTile(
              'Work Sprint',
              '24 Oct • 02:45 PM',
              '45m',
              Icons.bolt,
              Colors.amberAccent,
            ),
            const SizedBox(height: 12),
            _buildSessionTile(
              'Evening Wind Down',
              '23 Oct • 09:00 PM',
              '30m',
              Icons.bedtime,
              Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 12),
            _buildSessionTile(
              'Focus Time',
              '22 Oct • 11:30 AM',
              '60m',
              Icons.menu_book,
              Colors.orangeAccent,
            ),
            const SizedBox(height: 12),
            _buildSessionTile(
              'Midday Reset',
              '21 Oct • 01:15 PM',
              '10m',
              Icons.battery_charging_full,
              Colors.lightGreenAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(
    String title,
    String subtitle,
    String trailing,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
