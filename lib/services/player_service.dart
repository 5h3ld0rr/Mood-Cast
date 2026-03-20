import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:http/http.dart' as http;
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'audio_handler.dart';
import 'database_service.dart';
import 'download_service.dart';
import 'metrics_service.dart';
import 'mood_service.dart';
import 'community_service.dart';
import '../main.dart';

enum AudioQuality { low, medium, high }

class SongInfo {
  final String title;
  final String artist;
  final String? coverUrl;
  final String? previewUrl;
  final String? videoId;
  final String? localPath;
  final bool isPinned;

  String? get highResCoverUrl {
    if (coverUrl == null) return null;
    
    // If we have a videoId, we can often predict the best quality URL
    if (videoId != null) {
      if (coverUrl!.contains('img.youtube.com') || coverUrl!.contains('i.ytimg.com')) {
        return "https://img.youtube.com/vi/$videoId/maxresdefault.jpg";
      }
    }
    
    // Already in high res?
    if (coverUrl!.contains('maxresdefault.jpg') || coverUrl!.contains('=w1024')) {
      return coverUrl;
    }
    
    return coverUrl;
  }

  SongInfo({
    required this.title,
    required this.artist,
    this.coverUrl,
    this.previewUrl,
    this.videoId,
    this.localPath,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl,
      'previewUrl': previewUrl,
      'videoId': videoId,
      'localPath': localPath,
      'isPinned': isPinned,
    };
  }

  factory SongInfo.fromMap(Map<String, dynamic> map) {
    return SongInfo(
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      coverUrl: map['coverUrl'],
      previewUrl: map['previewUrl'],
      videoId: map['videoId'],
      localPath: map['localPath'],
      isPinned: map['isPinned'] ?? false,
    );
  }
}

/// Global cache: videoId → resolved AudioOnlyStreamInfo.
/// Avoids re-fetching the manifest on every play — cuts startup lag from ~2s → ~0.1s.
final Map<String, yt.AudioOnlyStreamInfo> _streamInfoCache = {};

/// Streams YouTube audio directly without downloading to a file.
/// Uses [StreamAudioSource] to pipe YouTube bytes to just_audio,
/// with range-request support for seeking.
class _YouTubeStreamAudioSource extends StreamAudioSource {
  final http.Client httpClient;
  final String videoId;
  final yt.YoutubeExplode _yt;
  final AudioQuality audioQuality;
  yt.AudioOnlyStreamInfo? _streamInfo;

  _YouTubeStreamAudioSource({
    required this.httpClient,
    required this.videoId,
    required yt.YoutubeExplode ytExplode,
    this.audioQuality = AudioQuality.high,
  }) : _yt = ytExplode;

  Future<void> _initStream() async {
    if (_streamInfo != null) return;

    // Check the global cache first — avoids refetching manifest on replay
    if (_streamInfoCache.containsKey(videoId)) {
      _streamInfo = _streamInfoCache[videoId];
      debugPrint('PlayerService: Cache hit for $videoId');
      return;
    }

    // Strictly use androidVr client — it bypasses many YouTube signature restrictions 
    // and is highly compatible with the manual HTTP requests we use below.
    final manifest = await _yt.videos.streamsClient.getManifest(
      videoId,
      ytClients: [yt.YoutubeApiClient.androidVr],
    );

    // Prefer WebM (Opus) first as it is more stable for streaming on Android
    final allAudio = manifest.audioOnly.sortByBitrate().toList();
    if (allAudio.isEmpty) throw Exception("No audio-only streams found for $videoId");

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

    // Store in cache for instant reuse
    if (_streamInfo != null) {
      _streamInfoCache[videoId] = _streamInfo!;
      // Evict oldest entries if cache grows too large
      if (_streamInfoCache.length > 30) {
        _streamInfoCache.remove(_streamInfoCache.keys.first);
      }
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

    // Use the shared persistent HTTP client to support range headers.
    // Persistent clients reuse TCP/TLS connections, cutting chunk latency by ~70%.
    final request = http.Request('GET', streamInfo.url);

    // Add essential headers to bypass YouTube restrictions
    request.headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36';
    request.headers['Range'] = 'bytes=$from-$finalTo';
    request.headers['Connection'] = 'keep-alive';

    final response = await httpClient.send(request).timeout(const Duration(seconds: 5));

    return StreamAudioResponse(
      sourceLength: totalBytes,
      contentLength: response.contentLength,
      offset: from,
      stream: response.stream,
      contentType: streamInfo.codec.mimeType,
    );
  }
}

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  final http.Client _httpClient = http.Client();
  final DatabaseService _db = DatabaseService();
  late MyAudioHandler _audioHandler;

  final ValueNotifier<SongInfo?> currentSong = ValueNotifier<SongInfo?>(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> isLiked = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isBuffering = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> position = ValueNotifier<Duration>(
    Duration.zero,
  );
  
  VoidCallback? onUserPlaybackAction;
  final ValueNotifier<Duration> duration = ValueNotifier<Duration>(
    const Duration(seconds: 1),
  );
  final ValueNotifier<bool> isShuffled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLooping = ValueNotifier<bool>(false);
  final ValueNotifier<AudioQuality> audioQuality = ValueNotifier<AudioQuality>(
    AudioQuality.high,
  );

  Timer? _sleepTimer;
  Timer? _fadeTimer;
  final ValueNotifier<Duration?> sleepTimerRemaining = ValueNotifier<Duration?>(null);

  Stream<ProcessingState> get processingStateStream => _audioPlayer.processingStateStream;

  List<SongInfo> currentQueue = [];
  List<SongInfo> _originalQueue = [];
  int currentIndex = -1;

  /// Pre-resolves a YouTube stream manifest in the background,
  /// populating the cache so the next play() call is near-instant.
  Future<void> prewarm(String videoId) async {
    if (_streamInfoCache.containsKey(videoId)) return; // already cached
    try {
      debugPrint('PlayerService: Pre-warming $videoId...');
      await _YouTubeStreamAudioSource(
        httpClient: _httpClient,
        videoId: videoId,
        ytExplode: _yt,
        audioQuality: audioQuality.value,
      )._initStream();
      debugPrint('PlayerService: Pre-warm done for $videoId');
    } catch (e) {
      debugPrint('PlayerService: Pre-warm failed for $videoId: $e');
    }
  }

  PlayerService._internal() {
    Duration lastPosition = Duration.zero;
    Duration accumulatedPlaytime = Duration.zero;

    _audioPlayer.positionStream.listen((p) {
      if (p > lastPosition) {
        final delta = p - lastPosition;
        if (delta.inSeconds < 5) {
          accumulatedPlaytime += delta;
        }
      }
      lastPosition = p;

      if (accumulatedPlaytime.inSeconds >= 10) {
        MetricsService.addPlaytime(accumulatedPlaytime);
        accumulatedPlaytime = Duration.zero;
      }

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
      if (d != null) {
        duration.value = d;
        // Update MediaItem when duration is resolved
        if (currentSong.value != null) {
          _audioHandler.updateMediaItemFromSong(currentSong.value!);
        }
      }
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

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(_audioPlayer),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.moodcast.audio.v3',
        androidNotificationChannelName: 'MoodCast',
        androidNotificationOngoing: false,
        androidStopForegroundOnPause: true,
        notificationColor: Color(0xFF00C2FF),
      ),
    );
  }

  Future<void> playQueue(List<SongInfo> queue, {int initialIndex = 0, bool isTribeSync = false}) async {
    if (!isTribeSync) onUserPlaybackAction?.call();
    
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

  Future<void> skipToNext({bool autoPlay = false, bool isTribeSync = false}) async {
    if (!autoPlay && !isTribeSync) onUserPlaybackAction?.call();

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

  Future<void> skipToPrevious({bool isTribeSync = false}) async {
    if (!isTribeSync) onUserPlaybackAction?.call();

    if (currentQueue.isEmpty || currentIndex < 0) return;
    if (position.value.inSeconds > 3) {
      await seek(0.0, isTribeSync: isTribeSync);
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

  Future<void> play(SongInfo song, {bool isTribeSync = false}) async {
    if (!isTribeSync) onUserPlaybackAction?.call();

    final stopwatch = Stopwatch()..start();
    debugPrint("PlayerService: Playback request starting for '${song.title}'");
    
    currentSong.value = song;
    progress.value = 0.0;
    position.value = Duration.zero;
    duration.value = const Duration(seconds: 1);
    isBuffering.value = true;

    // Background tasks: Update UI state and save history without blocking audio engine
    unawaited(() async {
      isLiked.value = await _db.isSongLiked(song);
      await _db.saveRecentTrack(song);
    }());

    // 1. UPDATE METADATA (NON-BLOCKING)
    unawaited(_audioHandler.updateMediaItemFromSong(song));
    debugPrint("PlayerService: UI Setup took ${stopwatch.elapsedMilliseconds}ms");

    try {
      // Calling stop() is slow; setAudioSource handles switching automatically.

      // 0. Check if it's a direct local file (not from YouTube)
      if (song.localPath != null && song.localPath!.isNotEmpty) {
        debugPrint("PlayerService: Playing direct local file: ${song.localPath}");
        await _audioPlayer.setAudioSource(AudioSource.file(song.localPath!));
        await _audioPlayer.play();
        return;
      }

      String? targetVideoId = song.videoId;

      // 1. Resolve videoId if missing
      if (targetVideoId == null || targetVideoId.isEmpty) {
        debugPrint("PlayerService: Searching for '${song.title} ${song.artist}'");
        final results = await _yt.search.search("${song.title} ${song.artist}");
        if (results.isNotEmpty) {
          targetVideoId = results.first.id.value;
        }
      }

      if (targetVideoId == null || targetVideoId.isEmpty) {
        isBuffering.value = false;
        return;
      }

      // 2. CONCURRENT: Start pre-warming and metadata fetch immediately
      final prewarmFuture = prewarm(targetVideoId);
      
      // Background: Fetch full metadata for high-res art (don't block playback)
      final vidId = targetVideoId;
      unawaited(() async {
        try {
          final video = await _yt.videos.get(vidId);
          final bestThumb = video.thumbnails.maxResUrl.isNotEmpty 
              ? video.thumbnails.maxResUrl 
              : video.thumbnails.standardResUrl.isNotEmpty 
                  ? video.thumbnails.standardResUrl 
                  : video.thumbnails.highResUrl;
          
          if (bestThumb.isNotEmpty && bestThumb != song.coverUrl) {
            final updatedSong = SongInfo(
              title: song.title,
              artist: song.artist,
              coverUrl: bestThumb,
              videoId: vidId,
              localPath: song.localPath,
              isPinned: song.isPinned,
            );
            currentSong.value = updatedSong;
            unawaited(_audioHandler.updateMediaItemFromSong(updatedSong));
          }
        } catch (e) {
          debugPrint("PlayerService: Metadata fetch failed: $e");
        }
      }());

      // 4. CONCURRENT: Check local path and pre-warm manifest simultaneously
      final resultsCheck = await Future.wait([
        DownloadService().getLocalPath(targetVideoId),
        prewarmFuture,
      ]);

      final localPath = resultsCheck[0] as String?;
      if (localPath != null) {
        debugPrint("PlayerService: Instant offline playback for $targetVideoId");
        await _audioPlayer.setAudioSource(AudioSource.file(localPath));
        _audioPlayer.play(); // No await so UI updates instantly
        return;
      }

      // 5. Final resolve for streaming
      debugPrint("PlayerService: Streaming $targetVideoId...");

        await _audioPlayer.setAudioSource(
          _YouTubeStreamAudioSource(
            httpClient: _httpClient,
            videoId: targetVideoId,
            ytExplode: _yt,
            audioQuality: audioQuality.value,
          ),
        );
        await _audioPlayer.play();
      debugPrint("PlayerService: Playback started!");

      // Pre-warm the next song in queue so it plays instantly when skipped to
      _prewarmNextInQueue();
    } catch (e, stack) {
      debugPrint("PlayerService ERROR: $e");
      debugPrint("Stack: $stack");
    } finally {
      // isBuffering reset removed here. 
      // The processingStateStream listener in Constructor handles it correctly 
      // based on the REAL player state (ProcessingState.buffering).
    }
  }

  /// Silently pre-warms the next song in the queue after current song starts.
  /// Runs fully in background \u2014 no await, no UI impact.
  void _prewarmNextInQueue() {
    final nextIndex = currentIndex + 1;
    if (nextIndex < currentQueue.length) {
      final nextVideoId = currentQueue[nextIndex].videoId;
      if (nextVideoId != null && nextVideoId.isNotEmpty) {
        prewarm(nextVideoId); // fire and forget
      }
    }
  }

  Future<void> toggleLiked() async {
    final song = currentSong.value;
    if (song != null) {
      await _db.toggleLikedSong(song);
      isLiked.value = !isLiked.value;
      
      // Automatically add/vibe to leaderboard if it is now "Liked"
      if (isLiked.value) {
        try {
          final currentMood = MoodService().currentMood.value;
          final validMoods = ['Happy', 'Sad', 'Angry', 'Chill', 'Focused'];
          final boardMood = validMoods.contains(currentMood) ? currentMood : 'Happy';

          await CommunityService().addSongToMoodboard(
            mood: boardMood,
            title: song.title,
            artist: song.artist,
            coverUrl: song.coverUrl,
            videoId: song.videoId,
          );
          debugPrint("PlayerService: Added/Vibed song automatically to $boardMood leaderboard");
        } catch (e) {
          debugPrint("PlayerService: Failed to auto-add to leaderboard: $e");
        }
      }
    }
  }

  Future<void> togglePlay({bool isTribeSync = false}) async {
    if (!isTribeSync) onUserPlaybackAction?.call();

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> stop({bool isTribeSync = false}) async {
    if (!isTribeSync) onUserPlaybackAction?.call();

    await _audioPlayer.stop();
    cancelSleepTimer();
    isPlaying.value = false;
    currentSong.value = null;
    progress.value = 0.0;
    position.value = Duration.zero;
    duration.value = const Duration(seconds: 1);
  }

  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    sleepTimerRemaining.value = duration;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sleepTimerRemaining.value != null) {
        final remaining = sleepTimerRemaining.value! - const Duration(seconds: 1);
        
        if (remaining.inSeconds <= 0) {
          timer.cancel();
          _initiateFadeOut();
        } else {
          sleepTimerRemaining.value = remaining;
        }
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _fadeTimer?.cancel();
    _fadeTimer = null;
    sleepTimerRemaining.value = null;
    _audioPlayer.setVolume(1.0); // Reset volume just in case
  }

  void _initiateFadeOut() {
    sleepTimerRemaining.value = const Duration(seconds: 0);
    double volume = _audioPlayer.volume;
    const int fadeOutDurationMs = 5000; // 5 seconds fade out
    const int stepMs = 100;
    final double volumeStep = volume / (fadeOutDurationMs / stepMs);

    _fadeTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      volume -= volumeStep;
      if (volume <= 0) {
        timer.cancel(); // Don't forget to cancel the periodic timer!
        _audioPlayer.setVolume(0.0);
        stop();
        
        // Use Global Navigator Key to close the PlayerScreen if it's currently showing
        // We look for the navigator state and pop since PlayerScreen is usually pushed as a full-screen route
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState?.pop();
        }
      } else {
        _audioPlayer.setVolume(volume);
      }
    });
  }

  Future<void> seek(double value, {bool isTribeSync = false}) async {
    if (!isTribeSync) onUserPlaybackAction?.call();

    final dur = _audioPlayer.duration;
    if (dur != null && dur.inMilliseconds > 0) {
      final pos = value * dur.inMilliseconds;
      await _audioPlayer.seek(Duration(milliseconds: pos.round()));
    }
  }

  Future<void> seekToPosition(Duration targetPosition, {bool isTribeSync = false}) async {
    if (!isTribeSync) onUserPlaybackAction?.call();
    await _audioPlayer.seek(targetPosition);
  }

  void clearQueue() {
    currentQueue.clear();
    _originalQueue.clear();
    currentIndex = -1;
  }

  void dispose() {
    _yt.close();
    _httpClient.close();
    _audioPlayer.dispose();
  }
}
