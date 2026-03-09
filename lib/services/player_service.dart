import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:http/http.dart' as http;
import 'database_service.dart';
import 'download_service.dart';

enum AudioQuality { low, medium, high }

class SongInfo {
  final String title;
  final String artist;
  final String? coverUrl;
  final String? previewUrl;
  final String? videoId;

  SongInfo({
    required this.title,
    required this.artist,
    this.coverUrl,
    this.previewUrl,
    this.videoId,
  });
}

/// Streams YouTube audio directly without downloading to a file.
/// Uses [StreamAudioSource] to pipe YouTube bytes to just_audio,
/// with range-request support for seeking.
class _YouTubeStreamAudioSource extends StreamAudioSource {
  final String videoId;
  final yt.YoutubeExplode _yt;
  final AudioQuality audioQuality;
  yt.AudioOnlyStreamInfo? _streamInfo;

  _YouTubeStreamAudioSource({
    required this.videoId,
    required yt.YoutubeExplode ytExplode,
    this.audioQuality = AudioQuality.high,
  }) : _yt = ytExplode;

  Future<void> _initStream() async {
    if (_streamInfo != null) return;

    // Use androidVr client — bypasses YouTube's API restrictions and 403s
    final manifest = await _yt.videos.streamsClient.getManifest(
      videoId,
      ytClients: [yt.YoutubeApiClient.androidVr],
    );

    // Prefer WebM (Opus) first as it is more stable for streaming on Android
    final allAudio = manifest.audioOnly.sortByBitrate().toList();
    final webmStreams = allAudio
        .where((s) => s.container.name == 'webm')
        .toList();

    final targetStreams = webmStreams.isNotEmpty ? webmStreams : allAudio;
    if (audioQuality == AudioQuality.low) {
      _streamInfo = targetStreams.first;
    } else if (audioQuality == AudioQuality.high) {
      _streamInfo = targetStreams.last;
    } else {
      _streamInfo = targetStreams[targetStreams.length ~/ 2];
    }
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    await _initStream();
    final streamInfo = _streamInfo!;

    final totalBytes = streamInfo.size.totalBytes;
    final from = start ?? 0;
    // If stream is throttled, limit the chunk size to avoid connection drops
    final to =
        (end ?? (streamInfo.isThrottled ? (from + 10379935) : totalBytes))
            .clamp(0, totalBytes);

    final finalTo = to >= totalBytes ? totalBytes - 1 : to;

    debugPrint(
      'YouTube stream request: bytes=$from-$finalTo / $totalBytes (${streamInfo.container.name})',
    );

    // Use a manual HTTP request to support range headers since the local
    // youtube_explode version's get() doesn't expose range parameters.
    final client = http.Client();
    final request = http.Request('GET', streamInfo.url);

    // Add essential headers to bypass YouTube restrictions
    request.headers['User-Agent'] =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.18 Safari/537.36';
    request.headers['Range'] = 'bytes=$from-$finalTo';

    final response = await client.send(request);

    return StreamAudioResponse(
      sourceLength: totalBytes,
      contentLength: response.contentLength,
      offset: from,
      stream: response.stream.asBroadcastStream(),
      contentType: streamInfo.codec.mimeType,
    );
  }
}

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  final DatabaseService _db = DatabaseService();

  final ValueNotifier<SongInfo?> currentSong = ValueNotifier<SongInfo?>(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> isLiked = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isBuffering = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> position = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<Duration> duration = ValueNotifier<Duration>(
    const Duration(seconds: 1),
  );
  final ValueNotifier<bool> isShuffled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLooping = ValueNotifier<bool>(false);
  final ValueNotifier<AudioQuality> audioQuality = ValueNotifier<AudioQuality>(
    AudioQuality.high,
  );

  List<SongInfo> currentQueue = [];
  List<SongInfo> _originalQueue = [];
  int currentIndex = -1;

  PlayerService._internal() {
    _audioPlayer.positionStream.listen((p) {
      position.value = p;
      final dur = _audioPlayer.duration;
      if (dur != null && dur.inMilliseconds > 0) {
        progress.value = p.inMilliseconds / dur.inMilliseconds;
      }
    });

    _audioPlayer.playingStream.listen((playing) {
      isPlaying.value = playing;
    });

    _audioPlayer.durationStream.listen((d) {
      if (d != null) duration.value = d;
    });

    _audioPlayer.processingStateStream.listen((state) {
      isBuffering.value =
          state == ProcessingState.loading ||
          state == ProcessingState.buffering;
      if (state == ProcessingState.completed) {
        skipToNext(autoPlay: true);
      }
    });
  }

  Future<void> playQueue(List<SongInfo> queue, {int initialIndex = 0}) async {
    if (queue.isEmpty) return;
    _originalQueue = List.from(queue);
    currentQueue = List.from(queue);

    if (isShuffled.value) {
      final currentSong = currentQueue[initialIndex];
      currentQueue.shuffle();
      currentIndex = currentQueue.indexOf(currentSong);
    } else {
      currentIndex = initialIndex;
    }

    await play(currentQueue[currentIndex]);
  }

  Future<void> skipToNext({bool autoPlay = false}) async {
    if (currentQueue.isEmpty || currentIndex < 0) return;

    if (autoPlay && isLooping.value) {
      // Loop the current song
      await play(currentQueue[currentIndex]);
      return;
    }

    if (currentIndex < currentQueue.length - 1) {
      currentIndex++;
    } else {
      if (autoPlay) return; // stop at end of playlist
      currentIndex = 0; // manual skip back to start
    }
    await play(currentQueue[currentIndex]);
  }

  Future<void> skipToPrevious() async {
    if (currentQueue.isEmpty || currentIndex < 0) return;
    if (position.value.inSeconds > 3) {
      await seek(0.0);
      return;
    }
    if (currentIndex > 0) {
      currentIndex--;
    } else {
      currentIndex = currentQueue.length - 1;
    }
    await play(currentQueue[currentIndex]);
  }

  void toggleShuffle() {
    isShuffled.value = !isShuffled.value;
    if (currentQueue.isEmpty || currentIndex < 0) return;

    final currentSong = currentQueue[currentIndex];
    if (isShuffled.value) {
      currentQueue.shuffle();
    } else {
      currentQueue = List.from(_originalQueue);
    }
    currentIndex = currentQueue.indexOf(currentSong);
  }

  void toggleLoop() {
    isLooping.value = !isLooping.value;
  }

  void setAudioQuality(AudioQuality quality) {
    audioQuality.value = quality;
  }

  Future<void> play(SongInfo song) async {
    currentSong.value = song;
    isLiked.value = await _db.isSongLiked(song);
    progress.value = 0.0;
    position.value = Duration.zero;
    duration.value = const Duration(seconds: 1);
    isBuffering.value = true;

    try {
      await _audioPlayer.stop();

      String? targetVideoId = song.videoId;

      if (targetVideoId == null || targetVideoId.isEmpty) {
        debugPrint(
          "PlayerService: Searching for '${song.title} ${song.artist}'",
        );
        final results = await _yt.search.search("${song.title} ${song.artist}");
        if (results.isNotEmpty) {
          targetVideoId = results.first.id.value;
          debugPrint("PlayerService: Found videoId: $targetVideoId");
        }
      }

      if (targetVideoId == null || targetVideoId.isEmpty) {
        debugPrint("PlayerService: No videoId found, cannot play.");
        isBuffering.value = false;
        return;
      }

      // 1. Check if song is downloaded
      final localPath = await DownloadService().getLocalPath(targetVideoId);
      if (localPath != null) {
        debugPrint(
          "PlayerService: Playing local file for $targetVideoId: $localPath",
        );
        await _audioPlayer.setAudioSource(AudioSource.file(localPath));
        await _audioPlayer.play();
        debugPrint("PlayerService: Offline playback started!");
        return;
      }

      debugPrint(
        "PlayerService: Streaming videoId=$targetVideoId via StreamAudioSource...",
      );

      // Using the androidVr client and StreamAudioSource avoids the 403 errors
      // and eliminates the need to download the entire file before playing.
      await _audioPlayer.setAudioSource(
        _YouTubeStreamAudioSource(
          videoId: targetVideoId,
          ytExplode: _yt,
          audioQuality: audioQuality.value,
        ),
      );
      await _audioPlayer.play();
      debugPrint("PlayerService: Playback started!");
    } catch (e, stack) {
      debugPrint("PlayerService ERROR: $e");
      debugPrint("Stack: $stack");
    } finally {
      isBuffering.value = false;
    }
  }

  void toggleLiked() async {
    final song = currentSong.value;
    if (song != null) {
      await _db.toggleLikedSong(song);
      isLiked.value = !isLiked.value;
    }
  }

  Future<void> togglePlay() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    isPlaying.value = false;
    currentSong.value = null;
    progress.value = 0.0;
    position.value = Duration.zero;
    duration.value = const Duration(seconds: 1);
  }

  Future<void> seek(double value) async {
    final dur = _audioPlayer.duration;
    if (dur != null && dur.inMilliseconds > 0) {
      final pos = value * dur.inMilliseconds;
      await _audioPlayer.seek(Duration(milliseconds: pos.round()));
    }
  }

  void dispose() {
    _yt.close();
    _audioPlayer.dispose();
  }
}
