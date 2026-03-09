import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../utils/ui_utils.dart';
import '../../services/database_service.dart';
import '../../services/player_service.dart';
import '../../widgets/song_options.dart';

class PlaylistDetailsScreen extends StatefulWidget {
  final String playlistName;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? playlistId;
  final bool isLikedSongs;

  const PlaylistDetailsScreen({
    super.key,
    required this.playlistName,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.playlistId,
    this.isLikedSongs = false,
  });

  @override
  State<PlaylistDetailsScreen> createState() => _PlaylistDetailsScreenState();
}

class _PlaylistDetailsScreenState extends State<PlaylistDetailsScreen> {
  final DatabaseService _db = DatabaseService();
  final PlayerService _player = PlayerService();

  void _showAddSongsSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddSongsBottomSheet(
        playlistId: widget.playlistId,
        onSongAdded: (song) {
          // Song is already added via DatabaseService in the bottom sheet
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF080C14),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.color.withValues(alpha: 0.4),
                      const Color(0xFF080C14),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 60),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.playlistName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showAddSongsSearch,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Songs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<List<SongInfo>>(
                    stream: widget.isLikedSongs
                        ? _db.getLikedSongs()
                        : _db.getPlaylistSongs(widget.playlistId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(
                                Icons.music_note,
                                color: Colors.white24,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Your playlist is empty',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final songs = snapshot.data!;
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: songs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final song = songs[index];
                          return _buildSongItem(song, index, songs);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongItem(SongInfo song, int index, List<SongInfo> queue) {
    return GestureDetector(
      onTap: () {
        _player.playQueue(queue, initialIndex: index);
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
              image: song.coverUrl != null
                  ? DecorationImage(
                      image: NetworkImage(song.coverUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: song.coverUrl == null
                ? const Icon(Icons.music_note, color: Colors.white38)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => SongOptionsBottomSheet(song: song),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddSongsBottomSheet extends StatefulWidget {
  final String? playlistId;
  final Function(SongInfo) onSongAdded;

  const _AddSongsBottomSheet({this.playlistId, required this.onSongAdded});

  @override
  State<_AddSongsBottomSheet> createState() => _AddSongsBottomSheetState();
}

class _AddSongsBottomSheetState extends State<_AddSongsBottomSheet> {
  final DatabaseService _db = DatabaseService();
  final List<SongInfo> _allSongs = [
    SongInfo(
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      coverUrl:
          'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=100',
    ),
    SongInfo(
      title: 'Starboy',
      artist: 'The Weeknd',
      coverUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=100',
    ),
    SongInfo(
      title: 'Save Your Tears',
      artist: 'The Weeknd',
      coverUrl:
          'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=100',
    ),
    SongInfo(title: 'Nightcall', artist: 'Kavinsky'),
    SongInfo(title: 'Midnight City', artist: 'M83'),
    SongInfo(title: 'Ocean Drive', artist: 'Duke Dumont'),
    SongInfo(title: 'Resonance', artist: 'Home'),
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredSongs = _allSongs
        .where(
          (song) =>
              song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              song.artist.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                hintText: 'Search songs or artists',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSongs.length,
              itemBuilder: (context, index) {
                final song = filteredSongs[index];
                return ListTile(
                  leading: const Icon(Icons.music_note, color: Colors.white38),
                  title: Text(
                    song.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primary,
                    ),
                    onPressed: () {
                      if (widget.playlistId != null) {
                        _db.addSongToPlaylist(widget.playlistId!, song);
                      } else {
                        _db.toggleLikedSong(song);
                      }
                      widget.onSongAdded(song);
                      UIUtils.showSnackBar(
                        context,
                        '${song.title} added',
                        duration: const Duration(seconds: 1),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
