import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:flutter/foundation.dart';
import 'player_service.dart';

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
  final String? description;
  final String? artworkUrl;
  final List<YouTubeMusicMetadata>? topSongs;
  final bool isPinned;

  YouTubeArtistMetadata({
    required this.browseId,
    required this.name,
    this.description,
    this.artworkUrl,
    this.topSongs,
    this.isPinned = false,
  });
}

class YouTubeMusicService {
  static final YouTubeMusicService _instance = YouTubeMusicService._internal();
  factory YouTubeMusicService() => _instance;
  YouTubeMusicService._internal();

  YTMusic? _ytm;

  Future<void> _initialize() async {
    _ytm ??= await YTMusic.create();
  }

  Future<List<YouTubeMusicMetadata>> searchTracks(String query) async {
    await _initialize();
    if (_ytm == null) return [];

    try {
      final results = await _ytm!.search(query, filter: SearchFilter.songs);
      return results.map((result) {
        final data = result as Map<String, dynamic>;

        // Extract artist name - handle list of artists
        String artistName = 'Unknown Artist';
        if (data['artist'] != null) {
          artistName = data['artist'];
        } else if (data['artists'] != null &&
            (data['artists'] as List).isNotEmpty) {
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

  Future<List<YouTubeArtistMetadata>> searchArtists(String query) async {
    await _initialize();
    if (_ytm == null) return [];

    try {
      final results = await _ytm!.search(query, filter: SearchFilter.artists);
      return results.map((result) {
        final data = result as Map<String, dynamic>;
        String? thumbnail;
        if (data['thumbnails'] != null &&
            (data['thumbnails'] as List).isNotEmpty) {
          thumbnail = data['thumbnails'].last['url'];
        }

        return YouTubeArtistMetadata(
          browseId: data['browseId'] ?? '',
          name: data['name'] ?? data['artist'] ?? 'Unknown Artist',
          artworkUrl: thumbnail,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error searching artists: $e');
      return [];
    }
  }

  Future<YouTubeArtistMetadata?> getArtistDetails(String browseId) async {
    await _initialize();
    if (_ytm == null) return null;

    try {
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
        name: data['name'] ?? 'Unknown Artist',
        description: data['description'] ?? '',
        artworkUrl: thumbnail,
        topSongs: topSongs,
      );
    } catch (e) {
      debugPrint('Error fetching artist details: $e');
      return null;
    }
  }

  @Deprecated('Use searchArtists and getArtistDetails instead')
  Future<YouTubeArtistMetadata?> searchArtist(String query) async {
    final results = await searchArtists(query);
    if (results.isEmpty) return null;
    return await getArtistDetails(results.first.browseId);
  }

  Future<List<YouTubeMusicMetadata>> getSmartRecommendations({
    required String mood,
    required List<SongInfo> likedSongs,
    String? country,
  }) async {
    // 1. If user has liked songs, prioritize similar music/recommendations
    if (likedSongs.isNotEmpty) {
      // Pick a random liked song to get similar music
      final randomSong = (likedSongs..shuffle()).first;
      final query = "${randomSong.title} ${randomSong.artist}";
      final results = await searchTracks(query);
      if (results.length > 3) return results;
    }

    // 2. Fallback: Search for trending music in their country or based on mood
    String query;
    if (country != null && country.isNotEmpty) {
      String countryName = _getCountryName(country);
      query = "trending music in $countryName";
    } else {
      query = _getQueryForMood(mood);
    }

    return await searchTracks(query);
  }

  String _getCountryName(String code) {
    final Map<String, String> countries = {
      'LK': 'Sri Lanka',
      'US': 'USA',
      'IN': 'India',
      'GB': 'UK',
      'CA': 'Canada',
      'AU': 'Australia',
      'MV': 'Maldives',
    };
    return countries[code.toUpperCase()] ?? code;
  }

  String _getQueryForMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return "happy uplifting music hits";
      case 'sad':
        return "sad emotional deep songs";
      case 'energetic':
        return "top upbeat energetic workout music";
      case 'calm':
        return "calm relaxing ambient peaceful music";
      case 'focused':
        return "lofi focus work study deep house";
      default:
        return "trending $mood music";
    }
  }

  Future<List<YouTubeMusicMetadata>> getRecommendationsByMood(
    String mood,
  ) async {
    return await searchTracks(_getQueryForMood(mood));
  }
}
