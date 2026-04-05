import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/player_service.dart';
import '../services/tribe_service.dart';

import '../screens/player.dart';
import '../../main.dart';
import 'cached_image.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SongInfo?>(
      valueListenable: PlayerService().currentSong,
      builder: (context, song, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: song == null
              ? const SizedBox.shrink()
              : KeyedSubtree(
                  key: ValueKey(song.title),
                  child: _MiniPlayerContent(song: song),
                ),
        );
      },
    );
  }
}

class _MiniPlayerContent extends StatefulWidget {
  final SongInfo song;
  const _MiniPlayerContent({required this.song});

  @override
  State<_MiniPlayerContent> createState() => _MiniPlayerContentState();
}

class _MiniPlayerContentState extends State<_MiniPlayerContent> {
  bool _isPressed = false;

  /// Returns true when the user is restricted from manual playback control.
  bool get _isInteractionLocked => TribeService().isInteractionLocked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.mediumImpact();

        navigatorKey.currentState?.push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black.withValues(alpha: 0.7),
            pageBuilder: (context, animation, secondaryAnimation) {
              return const PlayerScreen();
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Song Cover
                          Hero(
                            tag: 'player_art',
                            child: CachedImage(
                              imageUrl: widget.song.coverUrl,
                              width: 44,
                              height: 44,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Song Info
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.song.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.song.artist,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Controls
                          ValueListenableBuilder<bool>(
                            valueListenable: PlayerService().isLiked,
                            builder: (context, liked, _) {
                              return IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    key: ValueKey<bool>(liked),
                                    color: liked
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                                    size: 24,
                                  ),
                                ),
                                onPressed: () {
                                  PlayerService().toggleLiked();
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          ValueListenableBuilder<bool>(
                            valueListenable: PlayerService().isBuffering,
                            builder: (context, buffering, _) {
                              if (buffering) {
                                return SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                );
                              }
                              return ValueListenableBuilder<bool>(
                                valueListenable: PlayerService().isPlaying,
                                builder: (context, playing, _) {
                                  return IconButton(
                                    icon: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Icon(
                                        playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        key: ValueKey<bool>(playing),
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (!_isInteractionLocked) {
                                        PlayerService().togglePlay();
                                      }
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    // Progress Bar
                    ValueListenableBuilder<double>(
                      valueListenable: PlayerService().progress,
                      builder: (context, progress, _) {
                        return SizedBox(
                          height: 2,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
