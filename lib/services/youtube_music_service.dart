import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:flutter/foundation.dart';

class YouTubeMusicMetadata {
  final String videoId;
  final String title;
  final String artist;
  final String? artworkUrl;
  final Duration? duration;

  YouTubeMusicMetadata({
    required this.videoId,
    required this.title,
    required this.artist,
    this.artworkUrl,
    this.duration,
  });
}

class YouTubeArtistMetadata {
  final String browseId;
  final String name;
  final String description;
  final String? artworkUrl;
  final List<YouTubeMusicMetadata> topSongs;

  YouTubeArtistMetadata({
    required this.browseId,
    required this.name,
    required this.description,
    this.artworkUrl,
    required this.topSongs,
  });
}

class YouTubeMusicService {
  static final YouTubeMusicService _instance = YouTubeMusicService._internal();
  factory YouTubeMusicService() => _instance;
  YouTubeMusicService._internal();

  YTMusic? _ytm;

  Future<void> _initialize() async {
    if (_ytm != null) return;
    try {
      _ytm = await YTMusic.create();
    } catch (e) {
      debugPrint('Error initializing YouTube Music: $e');
    }
  }

  Future<List<YouTubeMusicMetadata>> searchTracks(String query) async {
    await _initialize();
    if (_ytm == null) return [];

    try {
      final results = await _ytm!.search(query, filter: SearchFilter.songs);
      return results.map((res) {
        final data = res as Map<String, dynamic>;

        // Extract artist name
        String artistName = 'Unknown Artist';
        if (data['artists'] != null && (data['artists'] as List).isNotEmpty) {
          artistName = data['artists'][0]['name'] ?? 'Unknown Artist';
        }

        // Extract thumbnail
        String? thumbnail;
        if (data['thumbnails'] != null &&
            (data['thumbnails'] as List).isNotEmpty) {
          thumbnail = data['thumbnails'].last['url']; // Get highest resolution
        }

        return YouTubeMusicMetadata(
          videoId: data['videoId'] ?? '',
          title: data['title'] ?? 'Unknown Title',
          artist: artistName,
          artworkUrl: thumbnail,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error searching YouTube Music: $e');
      return [];
    }
  }

  Future<YouTubeArtistMetadata?> searchArtist(String query) async {
    await _initialize();
    if (_ytm == null) return null;

    try {
      final results = await _ytm!.search(query, filter: SearchFilter.artists);
      if (results.isEmpty) return null;

      final firstArtist = results.first as Map<String, dynamic>;
      final browseId = firstArtist['browseId'];
      if (browseId == null) return null;

      final artistData = await _ytm!.getArtist(browseId);
      final data = artistData as Map<String, dynamic>;

      String? thumbnail;
      if (data['thumbnails'] != null &&
          (data['thumbnails'] as List).isNotEmpty) {
        thumbnail = data['thumbnails'].last['url'];
      }

      List<YouTubeMusicMetadata> topSongs = [];
      if (data['songs'] != null && data['songs']['results'] != null) {
        topSongs = (data['songs']['results'] as List).map((song) {
          final s = song as Map<String, dynamic>;
          String artistName = data['name'] ?? 'Unknown Artist';

          String? songThumbnail;
          if (s['thumbnails'] != null && (s['thumbnails'] as List).isNotEmpty) {
            songThumbnail = s['thumbnails'].last['url'];
          }

          return YouTubeMusicMetadata(
            videoId: s['videoId'] ?? '',
            title: s['title'] ?? 'Unknown Title',
            artist: artistName,
            artworkUrl: songThumbnail,
          );
        }).toList();
      }

      return YouTubeArtistMetadata(
        browseId: browseId,
        name: data['name'] ?? firstArtist['artist'] ?? 'Unknown Artist',
        description: data['description'] ?? '',
        artworkUrl: thumbnail,
        topSongs: topSongs,
      );
    } catch (e) {
      debugPrint('Error fetching artist details: $e');
      return null;
    }
  }

  Future<List<YouTubeMusicMetadata>> getRecommendationsByMood(
    String mood,
  ) async {
    // For YouTube Music, we'll map mood to a search query for now
    String query;
    switch (mood.toLowerCase()) {
      case 'happy':
        query = "happy uplifting music";
        break;
      case 'sad':
        query = "sad emotional songs";
        break;
      case 'energetic':
        query = "upbeat energetic music workout";
        break;
      case 'calm':
        query = "calm relaxing ambient music";
        break;
      case 'focused':
        query = "lofi focus work study music";
        break;
      default:
        query = "$mood music";
    }

    return await searchTracks(query);
  }
}
