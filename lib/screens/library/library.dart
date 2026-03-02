import 'package:flutter/material.dart';
import '../../theme.dart';
import 'playlist_details.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String selectedFilter = 'Playlists';

  final List<String> filters = ['Playlists', 'Artists', 'Albums', 'Downloaded'];

  // State for user-created playlists
  final List<Map<String, dynamic>> _customPlaylists = [];

  void _showCreatePlaylistDialog() {
    String playlistName = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Give your playlist a name',
                hintStyle: const TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppTheme.primary.withOpacity(0.5),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
              ),
              onChanged: (value) => playlistName = value,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (playlistName.isNotEmpty) {
                      setState(() {
                        _customPlaylists.insert(0, {
                          'title': playlistName,
                          'subtitle': '0 songs',
                          'icon': Icons.queue_music,
                          'color': AppTheme.primary,
                        });
                      });
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('CREATE'),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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
                    onPressed: _showCreatePlaylistDialog,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Chips for filtering
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildFilterChip(filter, selectedFilter == filter),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(child: _buildLibraryContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryContent() {
    switch (selectedFilter) {
      case 'Artists':
        return ListView(
          children: [
            _buildArtistItem(
              'The Midnight',
              '2.4M Monthly Listeners',
              'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200',
            ),
            const SizedBox(height: 16),
            _buildArtistItem(
              'Neon Horizon',
              '1.2M Monthly Listeners',
              'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200',
            ),
            const SizedBox(height: 16),
            _buildArtistItem(
              'Sunshine Collective',
              '850K Monthly Listeners',
              'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=200',
            ),
          ],
        );
      case 'Albums':
        return ListView(
          children: [
            _buildLibraryItem(
              'Endless Summer',
              'The Midnight • 2016',
              Icons.album,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildLibraryItem(
              'Kids',
              'The Midnight • 2018',
              Icons.album,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildLibraryItem(
              'Monsters',
              'The Midnight • 2020',
              Icons.album,
              Colors.purple,
            ),
          ],
        );
      case 'Downloaded':
        return ListView(
          children: [
            _buildLibraryItem(
              'Offline Mix',
              'Playlist • 50 songs',
              Icons.download_done,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildLibraryItem(
              'Starred Songs',
              'Playlist • 12 songs',
              Icons.star,
              Colors.amber,
            ),
          ],
        );
      case 'Playlists':
      default:
        return ListView(
          children: [
            // User custom playlists
            ..._customPlaylists.map(
              (playlist) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildLibraryItem(
                  playlist['title'] as String,
                  playlist['subtitle'] as String,
                  playlist['icon'] as IconData,
                  playlist['color'] as Color,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailsScreen(
                          playlistName: playlist['title'] as String,
                          subtitle: playlist['subtitle'] as String,
                          icon: playlist['icon'] as IconData,
                          color: playlist['color'] as Color,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Default playlists
            _buildLibraryItem(
              'Liked Songs',
              'Playlist • 124 songs',
              Icons.favorite,
              Colors.pink,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlaylistDetailsScreen(
                      playlistName: 'Liked Songs',
                      subtitle: 'Playlist • 124 songs',
                      icon: Icons.favorite,
                      color: Colors.pink,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildLibraryItem(
              'Morning Chill',
              'Playlist • By MoodCast',
              Icons.wb_sunny,
              Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlaylistDetailsScreen(
                      playlistName: 'Morning Chill',
                      subtitle: 'Playlist • By MoodCast',
                      icon: Icons.wb_sunny,
                      color: Colors.orange,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildLibraryItem(
              'Deep Focus',
              'Playlist • 45 songs',
              Icons.center_focus_strong,
              Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlaylistDetailsScreen(
                      playlistName: 'Deep Focus',
                      subtitle: 'Playlist • 45 songs',
                      icon: Icons.center_focus_strong,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildLibraryItem(
              'Recent Sessions',
              'History • 12 sessions',
              Icons.history,
              AppTheme.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlaylistDetailsScreen(
                      playlistName: 'Recent Sessions',
                      subtitle: 'History • 12 sessions',
                      icon: Icons.history,
                      color: AppTheme.primary,
                    ),
                  ),
                );
              },
            ),
          ],
        );
    }
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryItem(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
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
      ),
    );
  }

  Widget _buildArtistItem(String name, String followers, String imageUrl) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              followers,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}
