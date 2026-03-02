import 'package:flutter/material.dart';
import '../../theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Chips for filtering
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Playlists', true),
                    const SizedBox(width: 8),
                    _buildFilterChip('Artists', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('Albums', false),
                    const SizedBox(width: 8),
                    _buildFilterChip('Downloaded', false),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildLibraryItem(
                      'Liked Songs',
                      'Playlist • 124 songs',
                      Icons.favorite,
                      Colors.pink,
                    ),
                    const SizedBox(height: 16),
                    _buildLibraryItem(
                      'Morning Chill',
                      'Playlist • By MoodCast',
                      Icons.wb_sunny,
                      Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildLibraryItem(
                      'Deep Focus',
                      'Playlist • 45 songs',
                      Icons.center_focus_strong,
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildLibraryItem(
                      'Recent Sessions',
                      'History • 12 sessions',
                      Icons.history,
                      AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLibraryItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
