import 'package:flutter/material.dart';
import '../../theme.dart';

class CategoryDetailsScreen extends StatelessWidget {
  final String categoryName;
  final Color categoryColor;

  const CategoryDetailsScreen({
    super.key,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        title: Text(
          categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: categoryColor.withValues(alpha: 0.2),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    categoryColor.withValues(alpha: 0.4),
                    const Color(0xFF080C14),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  'Top $categoryName Hits',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Featured Songs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSongItem('Neon Lights', 'Vibe Master'),
                  _buildSongItem('Midnight Dream', 'Star Dust'),
                  _buildSongItem('Electric Sky', 'Future Pulse'),
                  _buildSongItem('Retro Wave', 'Synth Guru'),
                  _buildSongItem('Chill Clouds', 'Relax Rain'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongItem(String title, String artist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.music_note, color: categoryColor),
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
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.play_circle_fill, color: AppTheme.primary, size: 30),
        ],
      ),
    );
  }
}
