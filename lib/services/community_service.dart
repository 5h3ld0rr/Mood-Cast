import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_models.dart';
import 'weather_service.dart';

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
        .map((snapshot) {
          final now = DateTime.now();
          final validPosts = <CommunityPost>[];

          for (var doc in snapshot.docs) {
            final post = CommunityPost.fromFirestore(doc);

            if (post.isSupportRequest) {
              final isExpired = now.difference(post.timestamp).inHours >= 1;
              if (isExpired) {
                deletePost(post.id);
                continue;
              }
            }
            validPosts.add(post);
          }

          return validPosts;
        });
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
      id: '',
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
          final post = CommunityPost.fromFirestore(snapshot.docs.first);
          final now = DateTime.now();
          if (now.difference(post.timestamp).inHours >= 1) {
            deletePost(post.id);
            return null;
          }
          return post;
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
    String? videoId,
    String? coverUrl,
  }) async {
    if (uid == null) return;

    final response = SupportResponse(
      userId: uid!,
      userName: displayName!,
      songTitle: songTitle,
      artist: artist,
      videoId: videoId,
      coverUrl: coverUrl,
      moodColorValue: moodColorValue,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('community_posts').doc(postId).update({
      'supportResponses': FieldValue.arrayUnion([response.toMap()]),
    });

    await awardPoints(50);
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
    String? videoId,
  }) async {
    if (uid == null) return;

    if (videoId != null && videoId.isNotEmpty) {
      final query = await _firestore
          .collection('moodboards')
          .doc(mood)
          .collection('songs')
          .where('videoId', isEqualTo: videoId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'vibes': FieldValue.increment(1),
        });
        return;
      }
    }

    final song = MoodboardSong(
      id: '',
      title: title,
      artist: artist,
      coverUrl: coverUrl,
      videoId: videoId,
      vibes: 1,
      addedBy: displayName ?? 'Organic Pick',
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

    await awardPoints(5);
  }

  // --- User Mood Points & Tribes ---
  Future<void> awardPoints(int points) async {
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set({
      'moodPoints': FieldValue.increment(points),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserMood(String mood) async {
    if (uid == null) return;

    // Map country to Region for the Globe
    String region = 'ASIA'; // Default
    final country = WeatherService().currentWeather.value?.country ?? '';
    if (country == 'US' || country == 'CA') {
      region = 'US';
    } else if (['GB', 'FR', 'DE', 'IT', 'ES', 'NL', 'BE'].contains(country)) {
      region = 'EU';
    } else if (['CN', 'JP', 'IN', 'KR', 'SG', 'LK'].contains(country)) {
      region = 'ASIA';
    } else if (['BR', 'AR', 'MX', 'CO', 'CL'].contains(country)) {
      region = 'LA';
    } else if (['ZA', 'NG', 'KE', 'EG', 'MA'].contains(country)) {
      region = 'AF';
    }

    await _firestore.collection('users').doc(uid).set({
      'currentMood': mood,
      'region': region,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<int> getPoints() {
    if (uid == null) return Stream.value(0);
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0;
      return doc.data()?['moodPoints'] ?? 0;
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

  // --- Real-Time Regional Stats ---
  Stream<Map<String, int>> getRegionalMoodStats(String region) {
    // We listen to all users but filter locally for accuracy if region is ASIA (default)
    return _firestore.collection('users').snapshots().map((snapshot) {
      final now = DateTime.now();
      int happyCount = 0;
      int naturalCount = 0;
      int sadCount = 0;
      int angryCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        final mood = data['currentMood'] as String?;
        final userRegion = data['region'] as String? ?? 'ASIA';

        // Filter by region (ASIA is the catch-all for unset regions)
        if (userRegion != region) continue;

        // Consider someone 'online' if seen in last 10 minutes
        if (lastSeen != null &&
            (now.difference(lastSeen).inMinutes.abs() < 10)) {
          if (mood == 'Happy')
            happyCount++;
          else if (mood == 'Natural')
            naturalCount++;
          else if (mood == 'Sad')
            sadCount++;
          else if (mood == 'Angry')
            angryCount++;
        }
      }

      return {
        'Happy': happyCount,
        'Natural': naturalCount,
        'Sad': sadCount,
        'Angry': angryCount,
      };
    });
  }

  // --- Real-Time Global Stats ---
  Stream<GlobalMoodStats> getGlobalStats() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final now = DateTime.now();
      int happyCount = 0,
          naturalCount = 0,
          sadCount = 0,
          angryCount = 0,
          onlineCount = 0;
      final regionalMoodCounts = <String, Map<String, int>>{
        'US': {},
        'EU': {},
        'ASIA': {},
        'LA': {},
        'AF': {},
      };

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        final mood = data['currentMood'] as String?;
        final region = data['region'] as String? ?? 'ASIA';

        if (lastSeen != null && now.difference(lastSeen).inMinutes < 5) {
          onlineCount++;
          if (mood == 'Happy')
            happyCount++;
          else if (mood == 'Natural')
            naturalCount++;
          else if (mood == 'Sad')
            sadCount++;
          else if (mood == 'Angry')
            angryCount++;

          if (mood != null && regionalMoodCounts.containsKey(region)) {
            regionalMoodCounts[region]![mood] =
                (regionalMoodCounts[region]![mood] ?? 0) + 1;
          }
        }
      }

      int total = happyCount + naturalCount + sadCount + angryCount;
      if (total == 0) total = 1;

      final regionalMoods = <String, String>{};
      regionalMoodCounts.forEach((region, counts) {
        if (counts.isEmpty) {
          regionalMoods[region] = 'Natural';
        } else {
          final sortedMoods = counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          regionalMoods[region] = sortedMoods.first.key;
        }
      });

      return GlobalMoodStats(
        vibingNow: onlineCount,
        moodPercentages: {
          'Happy': ((happyCount / total) * 100).round(),
          'Natural': ((naturalCount / total) * 100).round(),
          'Sad': ((sadCount / total) * 100).round(),
          'Angry': ((angryCount / total) * 100).round(),
        },
        regionalMoods: regionalMoods,
      );
    });
  }
}
