import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../utils/ui_utils.dart';
import '../services/player_service.dart';
import '../services/mood_service.dart';
import '../services/download_service.dart';
import '../widgets/cached_image.dart';
import '../widgets/song_options.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(double seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds.toInt() % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F18),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A2333), Color(0xFF101827), Color(0xFF0A0F18)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Column(
                            children: [
                              Text(
                                'PLAYING FROM',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Wellness Player',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_horiz,
                              color: Colors.white,
                              size: 28,
                            ),
                            color: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'playlist':
                                  _showAddedToPlaylist();
                                  break;
                                case 'sleep':
                                  _showSleepTimerDialog();
                                  break;
                                case 'share':
                                  _handleShare();
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'playlist',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.playlist_add,
                                      size: 20,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Add to Playlist',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'sleep',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 20,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Sleep Timer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'share',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.share_outlined,
                                      size: 20,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Share',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Mood Badge
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.emergency,
                                color: AppTheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              ValueListenableBuilder<String>(
                                valueListenable: MoodService().currentMood,
                                builder: (context, mood, _) {
                                  return Text(
                                    'CURRENT MOOD: ${mood.toUpperCase()}',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Song Info Area (Now at Top)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: ValueListenableBuilder<SongInfo?>(
                        valueListenable: PlayerService().currentSong,
                        builder: (context, song, _) {
                          return Column(
                            children: [
                              Hero(
                                tag: 'player_art',
                                child: CachedImage(
                                  imageUrl: song?.coverUrl,
                                  width: 200,
                                  height: 200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                song?.title ?? 'Midnight Solitude',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                song?.artist ?? 'MoodCast • 432Hz Ambient',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<bool>(
                                valueListenable: PlayerService().isLiked,
                                builder: (context, liked, _) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ValueListenableBuilder<SongInfo?>(
                                        valueListenable:
                                            PlayerService().currentSong,
                                        builder: (context, song, _) {
                                          if (song == null) {
                                            return const SizedBox.shrink();
                                          }
                                          return ValueListenableBuilder<
                                            Map<String, double>
                                          >(
                                            valueListenable: DownloadService()
                                                .downloadProgress,
                                            builder: (context, progressMap, _) {
                                              final progress =
                                                  progressMap[song.videoId];
                                              final downloading =
                                                  progress != null;

                                              return ValueListenableBuilder<
                                                List<SongInfo>
                                              >(
                                                valueListenable:
                                                    DownloadService()
                                                        .downloadedSongs,
                                                builder: (context, downloadedSongs, _) {
                                                  final isDownloaded =
                                                      downloadedSongs.any(
                                                        (s) =>
                                                            s.videoId ==
                                                            song.videoId,
                                                      );

                                                  if (downloading) {
                                                    return SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            value: progress,
                                                            strokeWidth: 2,
                                                            color: AppTheme
                                                                .primary,
                                                          ),
                                                    );
                                                  }

                                                  return IconButton(
                                                    icon: Icon(
                                                      isDownloaded
                                                          ? Icons.download_done
                                                          : Icons
                                                                .download_for_offline_outlined,
                                                      color: isDownloaded
                                                          ? AppTheme.primary
                                                          : AppTheme.textMuted,
                                                      size: 24,
                                                    ),
                                                    onPressed: () {
                                                      if (isDownloaded) {
                                                        DownloadService()
                                                            .removeDownload(
                                                              song.videoId!,
                                                            );
                                                        UIUtils.showSnackBar(
                                                          context,
                                                          'Download removed',
                                                        );
                                                      } else {
                                                        DownloadService()
                                                            .downloadSong(song);
                                                        UIUtils.showSnackBar(
                                                          context,
                                                          'Starting download...',
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          liked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: liked
                                              ? AppTheme.primary
                                              : AppTheme.textMuted,
                                        ),
                                        onPressed: () {
                                          PlayerService().toggleLiked();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Animation Area (Waveform)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: MusicWaveform(
                            color: AppTheme.primary.withValues(alpha: 0.8),
                            count: 40,
                            isPlaying: PlayerService().isPlaying,
                          ),
                        ),
                      ),
                    ),

                    // Controls Area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 32),
                          ValueListenableBuilder<double>(
                            valueListenable: PlayerService().progress,
                            builder: (context, progress, _) {
                              return Column(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onHorizontalDragUpdate: (details) {
                                      final RenderBox box =
                                          context.findRenderObject()
                                              as RenderBox;
                                      final double width = box.size.width;
                                      final double relative =
                                          details.localPosition.dx / width;
                                      PlayerService().seek(
                                        relative.clamp(0.0, 1.0),
                                      );
                                    },
                                    onTapUp: (details) {
                                      final RenderBox box =
                                          context.findRenderObject()
                                              as RenderBox;
                                      final double width = box.size.width;
                                      final double relative =
                                          details.localPosition.dx / width;
                                      PlayerService().seek(
                                        relative.clamp(0.0, 1.0),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      child: Container(
                                        height: 6,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[900],
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: progress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ValueListenableBuilder<Duration>(
                                        valueListenable:
                                            PlayerService().position,
                                        builder: (context, pos, _) {
                                          return Text(
                                            _formatDuration(
                                              pos.inSeconds.toDouble(),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          );
                                        },
                                      ),
                                      ValueListenableBuilder<Duration>(
                                        valueListenable:
                                            PlayerService().duration,
                                        builder: (context, dur, _) {
                                          return Text(
                                            _formatDuration(
                                              dur.inSeconds.toDouble(),
                                            ),
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 10,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: PlayerService().isShuffled,
                                builder: (context, shuffled, _) {
                                  return IconButton(
                                    icon: Icon(
                                      Icons.shuffle,
                                      color: shuffled
                                          ? AppTheme.primary
                                          : AppTheme.textMuted,
                                    ),
                                    onPressed: () {
                                      PlayerService().toggleShuffle();
                                    },
                                  );
                                },
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_previous,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      PlayerService().skipToPrevious();
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () {
                                      PlayerService().togglePlay();
                                    },
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 15,
                                          ),
                                        ],
                                      ),
                                      child: ValueListenableBuilder<bool>(
                                        valueListenable:
                                            PlayerService().isBuffering,
                                        builder: (context, buffering, _) {
                                          if (buffering) {
                                            return const Padding(
                                              padding: EdgeInsets.all(16.0),
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 3,
                                              ),
                                            );
                                          }
                                          return ValueListenableBuilder<bool>(
                                            valueListenable:
                                                PlayerService().isPlaying,
                                            builder: (context, playing, _) {
                                              return Icon(
                                                playing
                                                    ? Icons.pause
                                                    : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 40,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_next,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: () {
                                      PlayerService().skipToNext();
                                    },
                                  ),
                                ],
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: PlayerService().isLooping,
                                builder: (context, looping, _) {
                                  return IconButton(
                                    icon: Icon(
                                      Icons.repeat,
                                      color: looping
                                          ? AppTheme.primary
                                          : AppTheme.textMuted,
                                    ),
                                    onPressed: () {
                                      PlayerService().toggleLoop();
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
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

  void _showAddedToPlaylist() {
    final song = PlayerService().currentSong.value;
    if (song == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlaylistSelector(song: song),
    );
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimerOption('15 Minutes', 15),
            _buildTimerOption('30 Minutes', 30),
            _buildTimerOption('60 Minutes', 60),
            _buildTimerOption('Custom', 0),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerOption(String label, int minutes) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      onTap: () {
        Navigator.pop(context);
        if (minutes == 0) {
          _showCustomTimeInput();
        } else {
          _setTimer(label, minutes);
        }
      },
    );
  }

  void _showCustomTimeInput() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Custom Timer',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter minutes',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary),
            ),
          ),
          onSubmitted: (value) {
            _processCustomTime(dialogContext, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _processCustomTime(dialogContext, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _processCustomTime(BuildContext dialogContext, String value) {
    if (value.isNotEmpty) {
      final mins = int.tryParse(value);
      if (mins != null && mins > 0) {
        Navigator.pop(dialogContext);
        _setTimer('$mins Minutes', mins);
      }
    }
  }

  void _setTimer(String label, int minutes) {
    UIUtils.showSnackBar(
      context,
      'Sleep timer set for $label',
      icon: Icons.timer_outlined,
    );
  }

  void _handleShare() {
    final song = PlayerService().currentSong.value;
    if (song == null) return;

    final shareUrl = song.videoId != null
        ? 'https://www.youtube.com/watch?v=${song.videoId}'
        : 'https://moodcast.ai/track';
    final shareText =
        'Check out ${song.title} by ${song.artist} on MoodCast! $shareUrl';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            // Track Share Card
            Container(
              width: MediaQuery.of(context).size.width * 0.75,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5E66),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Track Image
                  AspectRatio(
                    aspectRatio: 1,
                    child: CachedImage(
                      imageUrl: song.coverUrl,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'MoodCast',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
            const SizedBox(height: 24),
            // Interaction Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColorDot(const Color(0xFF8B5E66), isSelected: true),
                const SizedBox(width: 12),
                _buildColorDot(const Color(0xFF4A3439)),
                const SizedBox(width: 12),
                _buildColorDot(const Color(0xFF1A1A1A)),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Social Icons Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildShareAction(
                      'Copy link',
                      const Icon(Icons.link, color: Colors.white, size: 28),
                      Colors.grey[800]!,
                      () => _copyToClipboard(shareUrl),
                    ),
                    _buildShareAction(
                      'WhatsApp',
                      const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.white,
                        size: 28,
                      ),
                      const Color(0xFF25D366),
                      () => _launchURL(
                        'https://wa.me/?text=${Uri.encodeComponent(shareText)}',
                      ),
                    ),
                    _buildShareAction(
                      'Messages',
                      const Icon(Icons.message, color: Colors.white, size: 28),
                      const Color(0xFF007AFF),
                      () => _launchURL(
                        'sms:?body=${Uri.encodeComponent(shareText)}',
                      ),
                    ),
                    _buildShareAction(
                      'Stories',
                      const FaIcon(
                        FontAwesomeIcons.facebook,
                        color: Colors.white,
                        size: 28,
                      ),
                      const Color(0xFF1877F2),
                      () => _launchURL(
                        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}',
                      ),
                    ),
                    _buildShareAction(
                      'More',
                      const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 28,
                      ),
                      Colors.grey[700]!,
                      () => _handleGeneralShare(song),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    UIUtils.showSnackBar(
      context,
      'Link copied to clipboard!',
      icon: Icons.copy_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Try anyway as canLaunchUrl is sometimes unreliable on Android
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      UIUtils.showSnackBar(
        context,
        'Could not open the app. Please make sure it is installed.',
        isError: true,
      );
    }
  }

  Future<void> _handleGeneralShare(SongInfo song) async {
    final shareUrl = song.videoId != null
        ? 'https://www.youtube.com/watch?v=${song.videoId}'
        : 'https://moodcast.ai/track';
    try {
      debugPrint('Opening system share dialog...');
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Check out ${song.title} by ${song.artist} on MoodCast! $shareUrl',
          subject: 'Shared from MoodCast',
        ),
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (!mounted) return;
      UIUtils.showSnackBar(
        context,
        'Could not open system share.',
        isError: true,
      );
    }
  }

  Widget _buildColorDot(Color color, {bool isSelected = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
      ),
    );
  }

  Widget _buildShareAction(
    String label,
    Widget icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(child: icon),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class MusicWaveform extends StatefulWidget {
  final Color color;
  final int count;
  final ValueNotifier<bool> isPlaying;

  const MusicWaveform({
    super.key,
    required this.color,
    required this.isPlaying,
    this.count = 50,
  });

  @override
  State<MusicWaveform> createState() => _MusicWaveformState();
}

class _MusicWaveformState extends State<MusicWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isPlaying.value) {
      _controller.repeat();
    }

    widget.isPlaying.addListener(_handlePlaybackChange);
  }

  void _handlePlaybackChange() {
    if (widget.isPlaying.value) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    widget.isPlaying.removeListener(_handlePlaybackChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 60),
          painter: WaveformPainter(
            animationValue: _controller.value,
            color: widget.color,
            count: widget.count,
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final int count;

  WaveformPainter({
    required this.animationValue,
    required this.color,
    required this.count,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final double width = size.width;
    final double height = size.height;
    final double spacing = width / count;

    for (int i = 0; i < count; i++) {
      // Create a wave effect that moves from left to right
      // We use sine waves with different frequencies and phases
      final double x = i * spacing + spacing / 2;

      // Calculate height based on index and animation value
      // Center bars are taller, ends are shorter
      final double distFromCenter = (i - count / 2).abs() / (count / 2);
      final double baseHeight = (1.0 - distFromCenter * 0.7) * height;

      // Add animation variation
      final double variation =
          0.4 * math.sin(animationValue * 2 * math.pi + i * 0.2) +
          0.3 * math.sin(animationValue * 4 * math.pi + i * 0.5);

      final double barHeight = (baseHeight * (0.4 + 0.6 * variation)).clamp(
        4.0,
        height,
      );

      canvas.drawLine(
        Offset(x, height / 2 - barHeight / 2),
        Offset(x, height / 2 + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) => true;
}
