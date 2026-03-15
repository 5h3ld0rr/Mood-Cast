import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_models.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;
  String? get displayName => _auth.currentUser?.displayName ?? 'Anonymous';

  // --- Community Posts & Support Requests ---
  Stream<List<CommunityPost>> getPosts() {
    return _firestore
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommunityPost.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> createPost({
    required String content,
    required String userMood,
    required int moodColorValue,
    bool isSupportRequest = false,
    String? overrideUserName,
  }) async {
    if (uid == null) return;

    final post = CommunityPost(
      id: '', // Firestore will generate this
      userId: uid!,
      userName: overrideUserName ?? displayName!,
      userMood: userMood,
      content: content,
      timestamp: DateTime.now(),
      moodColorValue: moodColorValue,
      isSupportRequest: isSupportRequest,
      supportResponses: [],
      reactions: {'Relatable': 0, 'Vibing': 0, 'Healing': 0, 'Powerful': 0},
    );

    await _firestore.collection('community_posts').add(post.toMap());
  }

  Stream<CommunityPost?> getActiveSupportRequest() {
    if (uid == null) return Stream.value(null);
    return _firestore
        .collection('community_posts')
        .where('userId', isEqualTo: uid)
        .where('isSupportRequest', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CommunityPost.fromFirestore(snapshot.docs.first);
    });
  }

  Future<void> deletePost(String postId) async {
    await _firestore.collection('community_posts').doc(postId).delete();
  }

  Future<void> reactToPost(String postId, String reaction) async {
    final docRef = _firestore.collection('community_posts').doc(postId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      Map<String, dynamic> reactions = Map<String, dynamic>.from(
        snapshot.get('reactions') ?? {},
      );
      int currentCount = reactions[reaction] ?? 0;
      reactions[reaction] = currentCount + 1;

      transaction.update(docRef, {'reactions': reactions});
    });
  }

  Future<void> addSupportResponse({
    required String postId,
    required String songTitle,
    required String artist,
    required int moodColorValue,
  }) async {
    if (uid == null) return;

    final response = SupportResponse(
      userId: uid!,
      userName: displayName!,
      songTitle: songTitle,
      artist: artist,
      moodColorValue: moodColorValue,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('community_posts').doc(postId).update({
      'supportResponses': FieldValue.arrayUnion([response.toMap()]),
    });

    // Award empathy points
    await awardEmpathyPoints(50);
  }

  // --- Moodboards ---
  Stream<List<MoodboardSong>> getMoodboardSongs(String mood) {
    return _firestore
        .collection('moodboards')
        .doc(mood)
        .collection('songs')
        .orderBy('vibes', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MoodboardSong.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addSongToMoodboard({
    required String mood,
    required String title,
    required String artist,
    String? coverUrl,
  }) async {
    if (uid == null) return;

    final song = MoodboardSong(
      id: '',
      title: title,
      artist: artist,
      coverUrl: coverUrl,
      vibes: 1,
      addedBy: displayName!,
      addedById: uid!,
    );

    await _firestore
        .collection('moodboards')
        .doc(mood)
        .collection('songs')
        .add(song.toMap());
  }

  Future<void> vibeWithSong(String mood, String songId) async {
    await _firestore
        .collection('moodboards')
        .doc(mood)
        .collection('songs')
        .doc(songId)
        .update({'vibes': FieldValue.increment(1)});

    await awardEmpathyPoints(5);
  }

  // --- User Empathy Points & Tribes ---
  Future<void> awardEmpathyPoints(int points) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'empathyPoints': FieldValue.increment(points),
    }, SetOptions(merge: true));
  }

  Stream<int> getEmpathyPoints() {
    if (uid == null) return Stream.value(0);
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0;
      return doc.data()?['empathyPoints'] ?? 0;
    });
  }

  Future<void> toggleJoinTribe(String tribeId) async {
    if (uid == null) return;
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      List<String> joinedTribes = [];
      if (snapshot.exists) {
        joinedTribes = List<String>.from(snapshot.get('joinedTribes') ?? []);
      }

      if (joinedTribes.contains(tribeId)) {
        joinedTribes.remove(tribeId);
      } else {
        joinedTribes.add(tribeId);
      }

      transaction.set(userRef, {
        'joinedTribes': joinedTribes,
      }, SetOptions(merge: true));
    });
  }

  Stream<List<String>> getJoinedTribes() {
    if (uid == null) return Stream.value([]);
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return [];
      return List<String>.from(doc.data()?['joinedTribes'] ?? []);
    });
  }
}
