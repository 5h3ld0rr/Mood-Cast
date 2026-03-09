import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:shared_preferences/shared_preferences.dart';
import 'player_service.dart';

class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  final ValueNotifier<List<SongInfo>> downloadedSongs =
      ValueNotifier<List<SongInfo>>([]);
  final ValueNotifier<Map<String, double>> downloadProgress = ValueNotifier({});

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('downloaded_metadata') ?? [];

    final songs = <SongInfo>[];
    for (final jsonStr in jsonList) {
      try {
        final map = jsonDecode(jsonStr);
        final song = SongInfo.fromMap(map);

        // Cleanup any IDs that don't have files
        if (song.videoId != null && await getLocalPath(song.videoId!) != null) {
          songs.add(song);
        }
      } catch (e) {
        debugPrint("Error loading downloaded song metadata: $e");
      }
    }

    downloadedSongs.value = songs;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = downloadedSongs.value
        .map((s) => jsonEncode(s.toMap()))
        .toList();
    await prefs.setStringList('downloaded_metadata', jsonList);

    // Also keep the old one for compatibility if needed elsewhere
    final ids = downloadedSongs.value
        .where((s) => s.videoId != null)
        .map((s) => s.videoId!)
        .toList();
    await prefs.setStringList('downloaded_ids', ids);
  }

  Future<String> getDownloadPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(p.join(dir.path, 'downloads'));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  bool isDownloaded(String? videoId) {
    if (videoId == null) return false;
    return downloadedSongs.value.any((s) => s.videoId == videoId);
  }

  double getProgress(String? videoId) {
    if (videoId == null) return 0.0;
    return downloadProgress.value[videoId] ?? 0.0;
  }

  Future<void> downloadSong(SongInfo song) async {
    String? videoId = song.videoId;
    if (videoId == null || videoId.isEmpty) {
      try {
        final results = await _yt.search.search("${song.title} ${song.artist}");
        if (results.isNotEmpty) {
          videoId = results.first.id.value;
        }
      } catch (e) {
        debugPrint("Search failed during download: $e");
      }
    }

    if (videoId == null || videoId.isEmpty) return;
    if (isDownloaded(videoId)) return;
    if (downloadProgress.value.containsKey(videoId)) return;

    try {
      downloadProgress.value = {...downloadProgress.value, videoId: 0.1};

      final manifest = await _yt.videos.streamsClient.getManifest(
        videoId,
        ytClients: [yt.YoutubeApiClient.androidVr],
      );
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final stream = _yt.videos.streamsClient.get(streamInfo);

      final base = await getDownloadPath();
      final path = p.join(base, "$videoId.${streamInfo.container.name}");
      final file = File(path);

      if (await file.exists()) await file.delete();

      final fileStream = file.openWrite();

      int downloaded = 0;
      final total = streamInfo.size.totalBytes;

      await for (final data in stream) {
        fileStream.add(data);
        downloaded += data.length;
        final newProgress = downloaded / total;
        if (newProgress - (downloadProgress.value[videoId] ?? 0) > 0.05) {
          downloadProgress.value = {
            ...downloadProgress.value,
            videoId: newProgress,
          };
        }
      }

      await fileStream.flush();
      await fileStream.close();

      // Create a final song info with the correct videoId if it was fetched
      final finalSong = SongInfo(
        title: song.title,
        artist: song.artist,
        coverUrl: song.coverUrl,
        previewUrl: song.previewUrl,
        videoId: videoId,
      );

      downloadedSongs.value = [...downloadedSongs.value, finalSong];
      await _persist();

      downloadProgress.value = Map.from(downloadProgress.value)
        ..remove(videoId);
      debugPrint("Download complete: $videoId");
    } catch (e) {
      debugPrint("Download error: $e");
      downloadProgress.value = Map.from(downloadProgress.value)
        ..remove(videoId);
    }
  }

  Future<void> removeDownload(String videoId) async {
    final path = await getLocalPath(videoId);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }

    downloadedSongs.value = downloadedSongs.value
        .where((s) => s.videoId != videoId)
        .toList();
    await _persist();
  }

  Future<String?> getLocalPath(String videoId) async {
    final base = await getDownloadPath();
    final extensions = ['webm', 'm4a', 'mp3'];
    for (final ext in extensions) {
      final path = p.join(base, "$videoId.$ext");
      if (await File(path).exists()) return path;
    }
    return null;
  }
}
