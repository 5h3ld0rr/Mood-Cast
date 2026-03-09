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
  final ValueNotifier<Set<String>> downloadedIds = ValueNotifier<Set<String>>(
    {},
  );
  final ValueNotifier<Map<String, double>> downloadProgress = ValueNotifier({});

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('downloaded_ids') ?? [];
    downloadedIds.value = ids.toSet();

    // Cleanup any IDs that don't have files (maybe file was deleted)
    final cleanedIds = <String>{};
    for (final id in downloadedIds.value) {
      if (await getLocalPath(id) != null) {
        cleanedIds.add(id);
      }
    }

    if (cleanedIds.length != downloadedIds.value.length) {
      downloadedIds.value = cleanedIds;
      await prefs.setStringList('downloaded_ids', cleanedIds.toList());
    }
  }

  Future<String> getDownloadPath() async {
    // getApplicationDocumentsDirectory is safe for both iOS and Android
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(p.join(dir.path, 'downloads'));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  bool isDownloaded(String? videoId) {
    if (videoId == null) return false;
    return downloadedIds.value.contains(videoId);
  }

  double getProgress(String? videoId) {
    if (videoId == null) return 0.0;
    return downloadProgress.value[videoId] ?? 0.0;
  }

  Future<void> downloadSong(SongInfo song) async {
    String? videoId = song.videoId;
    if (videoId == null || videoId.isEmpty) {
      // Try to find it first
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
    if (downloadedIds.value.contains(videoId)) return;
    if (downloadProgress.value.containsKey(videoId)) return;

    try {
      downloadProgress.value = {...downloadProgress.value, videoId: 0.1};

      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      final stream = _yt.videos.streamsClient.get(streamInfo);

      final base = await getDownloadPath();
      final path = p.join(base, "$videoId.${streamInfo.container.name}");
      final file = File(path);

      // Delete old file if it exists but wasn't tracked
      if (await file.exists()) await file.delete();

      final fileStream = file.openWrite();

      int downloaded = 0;
      final total = streamInfo.size.totalBytes;

      await for (final data in stream) {
        fileStream.add(data);
        downloaded += data.length;
        // Update every 10% or so to avoid too many UI rebuilds
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

      // Save to prefs
      final prefs = await SharedPreferences.getInstance();
      downloadedIds.value = {...downloadedIds.value, videoId};
      await prefs.setStringList('downloaded_ids', downloadedIds.value.toList());

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

    final prefs = await SharedPreferences.getInstance();
    downloadedIds.value = Set.from(downloadedIds.value)..remove(videoId);
    await prefs.setStringList('downloaded_ids', downloadedIds.value.toList());
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
