import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../services/player_service.dart';
import '../services/download_service.dart';
import '../theme.dart';
import '../utils/ui_utils.dart';

class SongOptionsBottomSheet extends StatelessWidget {
  final SongInfo song;
  final String? playlistId;
  final bool isLikedSongs;
  final DatabaseService _db = DatabaseService();

  SongOptionsBottomSheet({
    super.key,
    required this.song,
    this.playlistId,
    this.isLikedSongs = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF080C14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            if (playlistId != null && !isLikedSongs)
              _buildActionItem(
                context,
                icon: Icons.playlist_remove,
                label: 'Remove from this Playlist',
                onTap: () async {
                  final safeTitle = song.title
                      .replaceAll(RegExp(r'[^\w\s]+'), '')
                      .replaceAll(' ', '_');
                  final safeArtist = song.artist
                      .replaceAll(RegExp(r'[^\w\s]+'), '')
                      .replaceAll(' ', '_');
                  final songId = song.videoId ?? '${safeTitle}_$safeArtist';

                  await _db.removeSongFromPlaylist(playlistId!, songId);
                  if (context.mounted) {
                    Navigator.pop(context);
                    UIUtils.showSnackBar(context, 'Removed from playlist');
                  }
                },
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
                final youtubeLink = song.videoId != null
                    ? 'https://www.youtube.com/watch?v=${song.videoId}'
                    : '';
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Check out "${song.title}" by ${song.artist} on MoodCast! $youtubeLink',
                  ),
                );
              },
            ),
            ValueListenableBuilder<List<SongInfo>>(
              valueListenable: DownloadService().downloadedSongs,
              builder: (context, downloadedSongs, _) {
                final isDownloaded =
                    song.videoId != null &&
                    downloadedSongs.any((s) => s.videoId == song.videoId);
                return ValueListenableBuilder<Map<String, double>>(
                  valueListenable: DownloadService().downloadProgress,
                  builder: (context, progressMap, _) {
                    final isDownloading =
                        song.videoId != null &&
                        progressMap.containsKey(song.videoId);

                    if (isDownloading) {
                      return _buildActionItem(
                        context,
                        icon: Icons.download_outlined,
                        label:
                            'Downloading (${(progressMap[song.videoId]! * 100).toInt()}%)',
                        iconColor: AppTheme.primary,
                        onTap: () {
                          // Do nothing while downloading
                        },
                      );
                    } else if (isDownloaded) {
                      final downloadedSong = downloadedSongs.firstWhere(
                        (s) => s.videoId == song.videoId,
                      );
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionItem(
                            context,
                            icon: downloadedSong.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            label: downloadedSong.isPinned
                                ? 'Unpin from Downloads'
                                : 'Pin to Downloads',
                            iconColor: AppTheme.primary,
                            onTap: () async {
                              await DownloadService().togglePinDownload(
                                song.videoId!,
                                downloadedSong.isPinned,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                UIUtils.showSnackBar(
                                  context,
                                  downloadedSong.isPinned
                                      ? 'Unpinned from downloads'
                                      : 'Pinned to downloads',
                                );
                              }
                            },
                          ),
                          _buildActionItem(
                            context,
                            icon: Icons.delete_outline,
                            label: 'Remove Download',
                            iconColor: Colors.white70,
                            onTap: () async {
                              await DownloadService().removeDownload(
                                song.videoId!,
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                UIUtils.showSnackBar(
                                  context,
                                  'Download removed',
                                );
                              }
                            },
                          ),
                        ],
                      );
                    } else {
                      return _buildActionItem(
                        context,
                        icon: Icons.download_outlined,
                        label: 'Download',
                        iconColor: Colors.white70,
                        onTap: () async {
                          DownloadService().downloadSong(song);
                          Navigator.pop(context);
                          UIUtils.showSnackBar(context, 'Added to downloads');
                        },
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
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
      builder: (context) => PlaylistSelector(song: song),
    );
  }
}

class PlaylistSelector extends StatelessWidget {
  final SongInfo song;
  final DatabaseService _db = DatabaseService();

  PlaylistSelector({required this.song});

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
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Add to Playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.add, color: AppTheme.primary),
            ),
            title: const Text(
              'New Playlist',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showCreatePlaylistDialog(context);
            },
          ),
          FutureBuilder<bool>(
            future: _db.isSongLiked(song),
            builder: (context, snapshot) {
              final isLiked = snapshot.data ?? false;
              return ListTile(
                leading: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: AppTheme.primary,
                ),
                title: const Text(
                  'Liked Songs',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  await _db.toggleLikedSong(song);
                  // Update PlayerService if this is the current song
                  if (PlayerService().currentSong.value?.videoId ==
                      song.videoId) {
                    PlayerService().isLiked.value = !isLiked;
                  }
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
          const Divider(color: Colors.white10),
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

  void _showCreatePlaylistDialog(BuildContext context) {
    String playlistName = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                  onPressed: () async {
                    if (playlistName.isNotEmpty) {
                      final playlistId = await _db.createPlaylist(playlistName);
                      if (playlistId != null) {
                        await _db.addSongToPlaylist(playlistId, song);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                        UIUtils.showSnackBar(
                          context,
                          'Added to new playlist "$playlistName"',
                        );
                      }
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
          ],
        ),
      ),
    );
  }
}
