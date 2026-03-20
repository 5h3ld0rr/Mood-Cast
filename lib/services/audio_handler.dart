import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'player_service.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;

  MyAudioHandler(this._player) {
    // Listen to playback state changes from the player and update the service's state.
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setRating(Rating rating, [Map<String, dynamic>? extras]) async {
    await PlayerService().toggleLiked();
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'toggleLike') {
      await PlayerService().toggleLiked();
    }
  }

  @override
  Future<void> skipToNext() async {
    // Forward the skip-to-next command to PlayerService
    await PlayerService().skipToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    // Forward the skip-to-previous command to PlayerService
    await PlayerService().skipToPrevious();
  }

  /// Transform a just_audio event into an audio_service PlaybackState.
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        const MediaControl(
          androidIcon: 'drawable/ic_heart',
          label: 'Like',
          action: MediaAction.setRating, // or use a custom action
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.setRating,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  /// Updates the media item (metadata) currently being played.
  Future<void> updateMediaItemFromSong(SongInfo song) async {
    final coverUrl = song.highResCoverUrl ?? song.coverUrl;

    // 1. UPDATE IMMEDIATELY with raw URL. 
    final initialMediaItem = MediaItem(
      id: song.videoId ?? 'temp',
      album: "MoodCast",
      title: song.title,
      artist: song.artist,
      artUri: coverUrl != null ? Uri.parse(coverUrl) : null,
      duration: _player.duration,
      extras: {
        'androidNotificationTitle': 'MoodCast',
        'playbackSource': 'MoodCast App',
      },
    );
    mediaItem.add(initialMediaItem);

    if (coverUrl == null || coverUrl.isEmpty) return;

    // 2. BACKGROUND PROCESSING
    unawaited(() async {
      try {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/notif_wide_${song.videoId ?? 'temp'}_${coverUrl.hashCode}.jpg';
        final file = File(filePath);

        if (!await file.exists()) {
          final response = await http.get(Uri.parse(coverUrl)).timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final original = img.decodeImage(bytes);

            if (original != null) {
              final targetHeight = (original.width / 3.7).toInt();
              final yOffset = (original.height - targetHeight) ~/ 2;
              
              final wideCrop = img.copyCrop(
                original, 
                x: 0, 
                y: yOffset > 0 ? yOffset : 0, 
                width: original.width, 
                height: targetHeight > original.height ? original.height : targetHeight
              );

              final finalOutput = img.copyResize(wideCrop, width: 512);
              await file.writeAsBytes(img.encodeJpg(finalOutput, quality: 85));
            }
          }
        }

        if (await file.exists()) {
          mediaItem.add(initialMediaItem.copyWith(artUri: Uri.file(filePath)));
        }
      } catch (e) {
        debugPrint('AudioHandler Image Processing Error: $e');
      }
    }());
  }
}
