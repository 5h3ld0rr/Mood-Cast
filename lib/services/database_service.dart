import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'player_service.dart';
import 'youtube_music_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // --- Liked Songs ---
  Future<void> toggleLikedSong(SongInfo song) async {
    if (uid == null) return;

    // Create a safe document ID
    final safeTitle = song.title
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final safeArtist = song.artist
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final songId = song.videoId ?? '${safeTitle}_$safeArtist';

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('liked_songs')
        .doc(songId);

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'title': song.title,
        'artist': song.artist,
        'coverUrl': song.coverUrl,
        'previewUrl': song.previewUrl,
        'videoId': song.videoId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isSongLiked(SongInfo song) async {
    if (uid == null) return false;
    final safeTitle = song.title
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final safeArtist = song.artist
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final songId = song.videoId ?? '${safeTitle}_$safeArtist';

    final docSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('liked_songs')
        .doc(songId)
        .get();
    return docSnap.exists;
  }

  Stream<List<SongInfo>> getLikedSongs() {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('liked_songs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return SongInfo(
              title: data['title'] ?? '',
              artist: data['artist'] ?? '',
              coverUrl: data['coverUrl'],
              previewUrl: data['previewUrl'],
              videoId: data['videoId'],
            );
          }).toList();
        });
  }

  // --- Playlists ---
  Future<String?> createPlaylist(String name, {bool isPublic = false}) async {
    if (uid == null) return null;
    final docRef = await _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .add({
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
          'songCount': 0,
          'coverUrl': null,
          'isPublic': isPublic,
          'creatorId': uid,
        });
    return docRef.id;
  }

  Future<void> deletePlaylist(String playlistId) async {
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId)
        .delete();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId)
        .update({'name': newName});
  }

  Future<void> togglePinPlaylist(String playlistId, bool isPinned) async {
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId)
        .update({'isPinned': !isPinned});
  }

  Future<void> togglePlaylistPrivacy(String playlistId, bool isPublic) async {
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId)
        .update({'isPublic': !isPublic});
  }

  Stream<List<Map<String, dynamic>>> getPlaylists() {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .snapshots()
        .map((snapshot) {
          final playlists = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();

          // Sort client-side to ensure documents without 'isPinned' are still included
          playlists.sort((a, b) {
            final aPinned = a['isPinned'] ?? false;
            final bPinned = b['isPinned'] ?? false;
            if (aPinned != bPinned) {
              return aPinned ? -1 : 1;
            }
            // Secondary sort by createdAt if available
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime != null && bTime != null) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });

          return playlists;
        });
  }

  Future<List<Map<String, dynamic>>> searchPublicPlaylists(String query) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('playlists')
          .where('isPublic', isEqualTo: true)
          .get();

      final playlists = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Get the creator's user ID from doc reference since collectionGroup returns docs from anywhere
        data['creatorId'] = doc.reference.parent.parent?.id; 
        return data;
      }).toList();

      if (query.isEmpty) return playlists;

      // Filter locally due to Firestore's text search limitations
      final lowerQuery = query.toLowerCase();
      return playlists.where((p) {
        final name = p['name']?.toString().toLowerCase() ?? '';
        return name.contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Error searching public playlists: $e');
      return [];
    }
  }

  Future<void> addSongToPlaylist(String playlistId, SongInfo song) async {
    if (uid == null) return;
    final safeTitle = song.title
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final safeArtist = song.artist
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .replaceAll(' ', '_');
    final songId = song.videoId ?? '${safeTitle}_$safeArtist';

    final playlistRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId);
    final songRef = playlistRef.collection('songs').doc(songId);

    final docSnap = await songRef.get();
    if (!docSnap.exists) {
      // Add song to playlist subcollection
      await songRef.set({
        'title': song.title,
        'artist': song.artist,
        'coverUrl': song.coverUrl,
        'previewUrl': song.previewUrl,
        'videoId': song.videoId,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // Update the parent playlist
      Map<String, dynamic> updates = {'songCount': FieldValue.increment(1)};
      if (song.coverUrl != null) {
        // We can just defensively set the cover to the last added song's cover if we want,
        // or only if it's currently null.
        final plSnap = await playlistRef.get();
        if (plSnap.exists && plSnap.data()?['coverUrl'] == null) {
          updates['coverUrl'] = song.coverUrl;
        }
      }
      await playlistRef.update(updates);
    }
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    if (uid == null) return;
    final playlistRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId);
    final songRef = playlistRef.collection('songs').doc(songId);

    final docSnap = await songRef.get();
    if (docSnap.exists) {
      await songRef.delete();
      await playlistRef.update({'songCount': FieldValue.increment(-1)});
    }
  }

  Stream<List<SongInfo>> getPlaylistSongs(String playlistId) {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .doc(playlistId)
        .collection('songs')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return SongInfo(
              title: data['title'] ?? '',
              artist: data['artist'] ?? '',
              coverUrl: data['coverUrl'],
              previewUrl: data['previewUrl'],
              videoId: data['videoId'],
            );
          }).toList();
        });
  }

  // --- Followed Artists ---
  Future<void> toggleFollowArtist(YouTubeArtistMetadata artist) async {
    if (uid == null) return;
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('followed_artists')
        .doc(artist.browseId);

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'name': artist.name,
        'browseId': artist.browseId,
        'artworkUrl': artist.artworkUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> isArtistFollowed(String browseId) async {
    if (uid == null) return false;
    final docSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('followed_artists')
        .doc(browseId)
        .get();
    return docSnap.exists;
  }

  Future<void> togglePinArtist(String browseId, bool isPinned) async {
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('followed_artists')
        .doc(browseId)
        .update({'isPinned': !isPinned});
  }

  Stream<List<YouTubeArtistMetadata>> getFollowedArtists() {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('followed_artists')
        .snapshots()
        .map((snapshot) {
          final artists = snapshot.docs.map((doc) {
            final data = doc.data();
            return YouTubeArtistMetadata(
              name: data['name'] ?? '',
              browseId: data['browseId'] ?? '',
              artworkUrl: data['artworkUrl'],
              isPinned: data['isPinned'] ?? false,
            );
          }).toList();

          // Sort client-side
          artists.sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }
            // We don't have timestamp here in the model, but we can add it if needed
            // For now just sort by name or keep original order
            return a.name.compareTo(b.name);
          });

          return artists;
        });
  }

  // --- Liked Albums ---
  Future<void> toggleLikedAlbum(YouTubeMusicMetadata album) async {
    if (uid == null) return;
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('liked_albums')
        .doc(album.videoId); // videoId used to store album browseId/id

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'title': album.title,
        'artist': album.artist,
        'artworkUrl': album.artworkUrl,
        'videoId': album.videoId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<YouTubeMusicMetadata>> getLikedAlbums() {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('liked_albums')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return YouTubeMusicMetadata(
              videoId: data['videoId'] ?? '',
              title: data['title'] ?? '',
              artist: data['artist'] ?? '',
              artworkUrl: data['artworkUrl'],
            );
          }).toList();
        });
  }

  // --- Recent Tracks ---
  Future<void> saveRecentTrack(SongInfo song) async {
    if (uid == null || song.videoId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('recent_tracks')
        .doc(song.videoId);

    await docRef.set({
      'title': song.title,
      'artist': song.artist,
      'coverUrl': song.coverUrl,
      'videoId': song.videoId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<SongInfo>> getRecentTracks({int limit = 10}) {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('recent_tracks')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return SongInfo(
              title: data['title'] ?? '',
              artist: data['artist'] ?? '',
              coverUrl: data['coverUrl'],
              videoId: data['videoId'],
            );
          }).toList();
        });
  }
}
