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
      final data = artistData;

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
    List<SongInfo> recentTracks = const [],
    String? country,
    String? weather,
  }) async {
    List<YouTubeMusicMetadata> finalResults = [];

    // 1. Personal Preference: Liked + Recent (variety mix)
    final combinedSeeds = [...likedSongs, ...recentTracks]..shuffle();

    if (combinedSeeds.isNotEmpty) {
      // Take up to 3 seeds to seed variety
      for (var seed in combinedSeeds.take(3)) {
        final query = "${seed.artist} radio mix";
        final results = await searchTracks(query);
        finalResults.addAll(results.take(5));
      }
    }

    // 2. Discover based on Mood
    final moodQuery = _getQueryForMood(mood, weather: weather);
    final moodResults = await searchTracks(moodQuery);
    finalResults.addAll(moodResults.take(10));

    // 3. Country Trending (Local Relevance)
    if (country != null && country.isNotEmpty) {
      final countryName = _getCountryName(country);
      final trendingResults = await searchTracks(
        "top trending $countryName hits",
      );
      finalResults.addAll(trendingResults.take(5));
    }

    // Shuffle and filter duplicates
    final seenIds = <String>{};
    final uniqueResults = finalResults
        .where((t) => seenIds.add(t.videoId))
        .toList();
    uniqueResults.shuffle();

    return uniqueResults.take(20).toList();
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

  String _getQueryForMood(String mood, {String? weather}) {
    String baseQuery;
    switch (mood.toLowerCase()) {
      case 'happy':
        baseQuery = "feel good anthems charts";
        break;
      case 'sad':
        baseQuery = "slow bittersweet acoustic piano ballads";
        break;
      case 'energetic':
        baseQuery = "high energy workout phonk edm";
        break;
      case 'calm':
        baseQuery = "peaceful meditation nature ambient";
        break;
      case 'focused':
        baseQuery = "lofi hip hop radio beats to study/relax to";
        break;
      case 'relaxing':
        baseQuery = "chill r&b soul vibes";
        break;
      case 'inspired':
        baseQuery = "epic cinematic orchestral motivation";
        break;
      case 'angry':
        baseQuery = "heavy metal breakdown aggressive hardcore";
        break;
      default:
        baseQuery = "popular $mood songs";
        break;
    }

    baseQuery += _getTimeOfDayModifier();
    baseQuery += _getWeatherModifier(weather);

    return baseQuery;
  }

  String _getTimeOfDayModifier() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return " morning";
    } else if (hour >= 12 && hour < 17) {
      return " afternoon";
    } else if (hour >= 17 && hour < 21) {
      return " evening";
    } else {
      return " late night midnight";
    }
  }

  String _getWeatherModifier(String? weather) {
    if (weather == null || weather.isEmpty) return "";

    switch (weather.toLowerCase()) {
      case 'rain':
      case 'drizzle':
      case 'rainy':
        return " rainy day cozy acoustic";
      case 'clear':
      case 'sunny':
        return " bright sunny upbeat";
      case 'clouds':
      case 'cloudy':
        return " cloudy moody atmosphere";
      case 'snow':
      case 'snowy':
        return " winter snow soft chilling";
      case 'thunderstorm':
        return " dark storm cinematic heavy";
      default:
        return " $weather weather";
    }
  }

  Future<List<YouTubeMusicMetadata>> getRecommendationsByMood(
    String mood, {
    String? weather,
  }) async {
    // Reuse smart recommendations logic but without liked songs context
    // This provides better variety than a single literal search
    return await getSmartRecommendations(
      mood: mood,
      weather: weather,
      likedSongs: [],
    );
  }

  Future<List<YouTubeArtistMetadata>> getSmartArtistRecommendations({
    required String mood,
    List<SongInfo> likedSongs = const [],
    List<SongInfo> recentTracks = const [],
    String? country,
    String? weather,
  }) async {
    final List<YouTubeArtistMetadata> finalArtists = [];
    final seenIds = <String>{};

    try {
      // 1. Personal Preference: Liked + Recent Artists
      final combinedSeeds = [...likedSongs, ...recentTracks]..shuffle();

      if (combinedSeeds.isNotEmpty) {
        for (var song in combinedSeeds.take(4)) {
          final results = await searchArtists(song.artist);
          if (results.isNotEmpty) {
            final artist = results.first;
            if (seenIds.add(artist.browseId)) finalArtists.add(artist);
          }
        }
      }

      // 2. Mood-Based Discovery
      final moodQuery = _getArtistQueryForMood(mood, weather: weather);
      final moodArtists = await searchArtists(moodQuery);
      for (var artist in moodArtists) {
        if (seenIds.add(artist.browseId)) finalArtists.add(artist);
      }

      // 3. Country Trending Artists
      if (country != null && country.isNotEmpty) {
        final countryName = _getCountryName(country);
        final trendingArtists = await searchArtists(
          "popular artists in $countryName",
        );
        for (var artist in trendingArtists.take(5)) {
          if (seenIds.add(artist.browseId)) finalArtists.add(artist);
        }
      }

      // Weighted Shuffle
      finalArtists.shuffle();
      return finalArtists.take(15).toList();
    } catch (e) {
      debugPrint('Error getting smart artist recommendations: $e');
      return finalArtists;
    }
  }

  String _getArtistQueryForMood(String mood, {String? weather}) {
    String baseQuery;
    switch (mood.toLowerCase()) {
      case 'happy':
        baseQuery = 'Mainstream Pop';
        break;
      case 'sad':
        baseQuery = 'Indie Alternative';
        break;
      case 'energetic':
        baseQuery = 'Dance Electronic';
        break;
      case 'calm':
        baseQuery = 'Classical Ambient';
        break;
      case 'focused':
        baseQuery = 'Lo-fi Beats';
        break;
      case 'relaxing':
        baseQuery = 'Neo-Soul Jazz';
        break;
      case 'inspired':
        baseQuery = 'Cinematic Composers';
        break;
      case 'angry':
        baseQuery = 'Hard Rock Metal';
        break;
      default:
        baseQuery = 'Trending Artists';
        break;
    }

    baseQuery += _getTimeOfDayModifier();

    // For artists, keep weather influence lighter
    if (weather != null && weather.isNotEmpty) {
      baseQuery += " $weather";
    }

    return baseQuery;
  }
}
