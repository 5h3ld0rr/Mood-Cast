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
    Uri? finalArtUri;
    // Use the maximum resolution available from youtube
    final coverUrl = song.highResCoverUrl ?? song.coverUrl;

    if (coverUrl != null && coverUrl.isNotEmpty) {
      try {
        final tempDir = await getTemporaryDirectory();
        final filePath =
            '${tempDir.path}/notif_edge_${song.videoId ?? 'temp'}_${coverUrl.hashCode}.jpg';
        final file = File(filePath);

        if (!await file.exists()) {
          debugPrint('AudioHandler: Creating ultra-wide full-width crop for $coverUrl');
          final response = await http.get(Uri.parse(coverUrl));
          if (response.statusCode == 200) {
            final bytes = response.bodyBytes;
            final original = img.decodeImage(bytes);

            if (original != null) {
              // Create an ultra-wide rectangle to fill the system tray end-to-edge
              // Target ratio is roughly 3:7 for modern Android notification trays
              final targetWidth = original.width;
              final targetHeight = (targetWidth / 3.7).toInt(); // Sharp wide rectangle
              
              // Center crop from top and bottom
              final yOffset = (original.height - targetHeight) ~/ 2;
              
              final wideCrop = img.copyCrop(
                original, 
                x: 0, 
                y: yOffset > 0 ? yOffset : 0, 
                width: targetWidth, 
                height: targetHeight > original.height ? original.height : targetHeight
              );

              // 4. Save at 1024 width for performance
              final finalOutput = img.copyResize(wideCrop, width: 1024);
              await file.writeAsBytes(img.encodeJpg(finalOutput, quality: 95));
              debugPrint('AudioHandler: Saved 3:7 full-width cropped cover to ${file.path}');
            }
          }
        }

        if (await file.exists()) {
          finalArtUri = Uri.file(filePath);
        } else {
          finalArtUri = Uri.parse(coverUrl);
        }
      } catch (e) {
        debugPrint('AudioHandler: Error smoothing: $e');
        finalArtUri = Uri.parse(coverUrl);
      }
    }

    mediaItem.add(MediaItem(
      // Appending timestamp to ID FORCES the OS to ignore its internal cache and re-fetch the image
      id: '${song.videoId ?? 'temp'}_${DateTime.now().millisecondsSinceEpoch}',
      album: "MoodCast",
      title: song.title,
      artist: song.artist,
      artUri: finalArtUri,
      duration: _player.duration,
      extras: {
        'androidNotificationTitle': 'MoodCast',
        'playbackSource': 'MoodCast App',
      },
    ));
  }
}
