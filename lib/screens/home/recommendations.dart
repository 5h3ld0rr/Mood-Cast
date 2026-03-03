import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/player_service.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        title: const Text(
          'Recommended for You',
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
            _buildSongTile(
              context,
              'Happy Vibes',
              'Sunshine Collective',
              Icons.play_circle_fill,
            ),
            const SizedBox(height: 12),
            _buildSongTile(
              context,
              'Summer Pop',
              'Neon Horizon',
              Icons.play_circle_fill,
            ),
            const SizedBox(height: 12),
            _buildSongTile(
              context,
              'Golden Hour',
              'The Midnight',
              Icons.play_circle_fill,
            ),
            const SizedBox(height: 12),
            _buildSongTile(
              context,
              'Midnight City',
              'M83',
              Icons.play_circle_fill,
            ),
            const SizedBox(height: 12),
            _buildSongTile(
              context,
              'Lofi Dreams',
              'Study Beats',
              Icons.play_circle_fill,
            ),
            const SizedBox(height: 12),
            _buildSongTile(
              context,
              'Chill Waves',
              'Ocean Breeze',
              Icons.play_circle_fill,
            ),
            const SizedBox(height: 12),
            _buildSongTile(
              context,
              'Starlight',
              'Muse',
              Icons.play_circle_fill,
            ),
            const SizedBox(height: 12),
            _buildSongTile(
              context,
              'Electric Feel',
              'MGMT',
              Icons.play_circle_fill,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(
    BuildContext context,
    String title,
    String artist,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        PlayerService().play(SongInfo(title: title, artist: artist));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: Colors.white54),
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
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    artist,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: AppTheme.primary, size: 40),
          ],
        ),
      ),
    );
  }
}
