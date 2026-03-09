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
  Future<void> createPlaylist(String name) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).collection('playlists').add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
      'songCount': 0,
      'coverUrl': null,
    });
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

  Stream<List<Map<String, dynamic>>> getPlaylists() {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('playlists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
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

  Stream<List<YouTubeArtistMetadata>> getFollowedArtists() {
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('followed_artists')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return YouTubeArtistMetadata(
              name: data['name'] ?? '',
              browseId: data['browseId'] ?? '',
              artworkUrl: data['artworkUrl'],
            );
          }).toList();
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
}
