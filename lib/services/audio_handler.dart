import 'dart:async';
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
    // Use the maximum resolution available from youtube
    final coverUrl = song.highResCoverUrl ?? song.coverUrl;

    mediaItem.add(MediaItem(
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
    ));
  }
}
