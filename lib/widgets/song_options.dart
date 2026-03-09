import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/player_service.dart';
import '../theme.dart';
import '../utils/ui_utils.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  final SongInfo song;
  final DatabaseService _db = DatabaseService();

  SongOptionsBottomSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(color: Colors.white10),
          _buildActionItem(
            context,
            icon: Icons.playlist_add,
            label: 'Add to Playlist',
            onTap: () => _showPlaylistSelector(context),
          ),
          FutureBuilder<bool>(
            future: _db.isSongLiked(song),
            builder: (context, snapshot) {
              final isLiked = snapshot.data ?? false;
              return _buildActionItem(
                context,
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                label: isLiked
                    ? 'Remove from Liked Songs'
                    : 'Add to Liked Songs',
                iconColor: isLiked ? Colors.pink : Colors.white70,
                onTap: () async {
                  await _db.toggleLikedSong(song);
                  if (context.mounted) {
                    Navigator.pop(context);
                    UIUtils.showSnackBar(
                      context,
                      isLiked
                          ? 'Removed from Liked Songs'
                          : 'Added to Liked Songs',
                    );
                  }
                },
              );
            },
          ),
          _buildActionItem(
            context,
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {
              Navigator.pop(context);
              UIUtils.showSnackBar(context, 'Share feature coming soon!');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 50,
              height: 50,
              color: Colors.white10,
              child: song.coverUrl != null
                  ? Image.network(song.coverUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.music_note, color: Colors.white24),
            ),
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white70,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _showPlaylistSelector(BuildContext context) {
    Navigator.pop(context); // Close song options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlaylistSelector(song: song),
    );
  }
}

class _PlaylistSelector extends StatelessWidget {
  final SongInfo song;
  final DatabaseService _db = DatabaseService();

  _PlaylistSelector({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              'Add to Playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
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
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No playlists yet. Create one in your Library!',
                        style: TextStyle(color: Colors.white60),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final playlists = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.queue_music,
                        color: AppTheme.primary,
                      ),
                      title: Text(
                        playlist['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        _db.addSongToPlaylist(playlist['id'], song);
                        Navigator.pop(context);
                        UIUtils.showSnackBar(
                          context,
                          'Added to ${playlist['name']}',
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
