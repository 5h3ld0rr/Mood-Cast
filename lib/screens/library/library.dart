import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/database_service.dart';
import '../../services/player_service.dart';
import 'playlist_details.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String selectedFilter = 'Playlists';
  final List<String> filters = ['Playlists', 'Artists', 'Albums', 'Downloaded'];

  final DatabaseService _db = DatabaseService();

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
                    color: AppTheme.primary.withValues(alpha: 0.5),
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
                      _db.createPlaylist(playlistName);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  const Text(
                    'Your Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                    onPressed: _showCreatePlaylistDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Chips for filtering
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: filters.map((filter) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildFilterChip(filter, selectedFilter == filter),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildLibraryContent(),
              ),
            ),
          ],
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
          physics: const BouncingScrollPhysics(),
          children: [
            _buildLibraryItem(
              'Endless Summer',
              'The Midnight • 2016',
              Icons.album,
              Colors.orange,
              imageUrl:
                  'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=200',
            ),
            const SizedBox(height: 16),
            _buildLibraryItem(
              'Kids',
              'The Midnight • 2018',
              Icons.album,
              Colors.blue,
              imageUrl:
                  'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=200',
            ),
            const SizedBox(height: 16),
            _buildLibraryItem(
              'Monsters',
              'The Midnight • 2020',
              Icons.album,
              Colors.purple,
              imageUrl:
                  'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=200',
            ),
          ],
        );
      case 'Downloaded':
        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildLibraryItem(
              'Offline Mix',
              'Playlist • 50 songs',
              Icons.download_done,
              Colors.green,
              imageUrl:
                  'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200',
            ),
            const SizedBox(height: 16),
            _buildLibraryItem(
              'Starred Songs',
              'Playlist • 12 songs',
              Icons.star,
              Colors.amber,
              imageUrl:
                  'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=200',
            ),
          ],
        );
      case 'Playlists':
      default:
        return Column(
          children: [
            // User Liked Songs Playlist (Static position)
            StreamBuilder<List<SongInfo>>(
              stream: _db.getLikedSongs(),
              builder: (context, snapshot) {
                final count = snapshot.hasData ? snapshot.data!.length : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildLibraryItem(
                    'Liked Songs',
                    'Playlist • $count songs',
                    Icons.favorite,
                    Colors.pink,
                    isLikedSongs: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlaylistDetailsScreen(
                            playlistName: 'Liked Songs',
                            subtitle: 'Your Liked Songs',
                            icon: Icons.favorite,
                            color: Colors.pink,
                            isLikedSongs: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Firestore Data Playlists
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.getPlaylists(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'No playlists yet',
                        style: TextStyle(color: Colors.white60),
                      ),
                    );
                  }

                  final playlists = snapshot.data!;
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ...playlists.map(
                        (playlist) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildLibraryItem(
                            playlist['name'] as String,
                            'Playlist • ${playlist['songCount']} songs',
                            Icons.queue_music,
                            AppTheme.primary,
                            imageUrl: playlist['coverUrl'],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlaylistDetailsScreen(
                                    playlistName: playlist['name'] as String,
                                    subtitle:
                                        'Playlist • ${playlist['songCount']} songs',
                                    icon: Icons.queue_music,
                                    color: AppTheme.primary,
                                    playlistId: playlist['id'] as String,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
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
          color: isSelected
              ? AppTheme.primary
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.white.withValues(alpha: 0.1),
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
    String? imageUrl,
    bool isLikedSongs = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isLikedSongs ? null : color.withValues(alpha: 0.1),
                gradient: isLikedSongs
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF450af5), Color(0xFFc4efd9)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(4),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null
                  ? isLikedSongs
                        ? const Center(
                            child: Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 28,
                            ),
                          )
                        : Icon(icon, color: color, size: 28)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isLikedSongs)
                        const Padding(
                          padding: EdgeInsets.only(right: 4.0),
                          child: Icon(
                            Icons.push_pin,
                            color: AppTheme.primary,
                            size: 12,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
