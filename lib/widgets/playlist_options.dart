import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../theme.dart';
import '../utils/ui_utils.dart';

class PlaylistOptionsBottomSheet extends StatelessWidget {
  final String playlistId;
  final String playlistName;
  final bool isLikedSongs;
  final DatabaseService _db = DatabaseService();

  PlaylistOptionsBottomSheet({
    super.key,
    required this.playlistId,
    required this.playlistName,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(color: Colors.white10),
          _buildActionItem(
            context,
            icon: Icons.share_outlined,
            label: 'Share Playlist',
            onTap: () {
              Navigator.pop(context);
              SharePlus.instance.share(
                ShareParams(
                  text: 'Check out my "$playlistName" playlist on MoodCast!',
                ),
              );
            },
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _db.getPlaylists().first,
            builder: (context, snapshot) {
              final pl = snapshot.data?.firstWhere(
                (p) => p['id'] == playlistId,
                orElse: () => {},
              );
              final isPinned = pl?['isPinned'] ?? false;

              return _buildActionItem(
                context,
                icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: isPinned ? 'Unpin Playlist' : 'Pin Playlist',
                onTap: () async {
                  await _db.togglePinPlaylist(playlistId, isPinned);
                  if (context.mounted) {
                    Navigator.pop(context);
                    UIUtils.showSnackBar(
                      context,
                      isPinned ? 'Playlist unpinned' : 'Playlist pinned',
                    );
                  }
                },
              );
            },
          ),
          if (!isLikedSongs) ...[
            _buildActionItem(
              context,
              icon: Icons.edit_outlined,
              label: 'Edit Playlist Name',
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context);
              },
            ),
            _buildActionItem(
              context,
              icon: Icons.delete_outline,
              label: 'Delete Playlist',
              iconColor: Colors.redAccent,
              onTap: () => _showDeleteConfirmation(context),
            ),
          ],
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.queue_music, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Playlist Options',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF080C14),
        title: const Text(
          'Delete Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "$playlistName"? This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await _db.deletePlaylist(playlistId);
        if (context.mounted) {
          // Return 'deleted' signal to the PlaylistDetailsScreen
          Navigator.pop(context, 'deleted');
          UIUtils.showSnackBar(context, 'Playlist deleted');
        }
      }
    });
  }

  void _showRenameDialog(BuildContext context) {
    String newName = playlistName;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF080C14),
        title: const Text(
          'Rename Playlist',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new name',
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
          onChanged: (value) => newName = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (newName.isNotEmpty && newName != playlistName) {
                await _db.renamePlaylist(playlistId, newName);
                if (context.mounted) {
                  UIUtils.showSnackBar(
                    context,
                    'Playlist renamed to "$newName"',
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text(
              'SAVE',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
