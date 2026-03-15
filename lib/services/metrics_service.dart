import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MetricsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DocumentReference? get _userDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  // Scans
  static Future<void> saveMoodScan(String mood) async {
    final docRef = _userDoc;
    if (docRef == null) return;

    // 1. Update Streak
    final userSnap = await docRef.get();
    final userData = userSnap.data() as Map<String, dynamic>?;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int currentStreak = userData?['current_streak'] ?? 0;
    final lastStreakTimestamp = userData?['last_streak_date'] as Timestamp?;

    if (lastStreakTimestamp != null) {
      final lastDate = lastStreakTimestamp.toDate();
      final lastStreakDate = DateTime(
        lastDate.year,
        lastDate.month,
        lastDate.day,
      );
      final difference = today.difference(lastStreakDate).inDays;

      if (difference == 1) {
        currentStreak++;
      } else if (difference > 1) {
        currentStreak = 1;
      }
      // If difference is 0, same day, streak stays same
    } else {
      currentStreak = 1;
    }

    // 2. Update streak and history
    await docRef.set({
      'current_streak': currentStreak,
      'last_streak_date': Timestamp.fromDate(today),
    }, SetOptions(merge: true));

    // Save to history
    await docRef.collection('mood_history').add({
      'mood': mood,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<Map<String, dynamic>>> getMoodHistoryStream() {
    final docRef = _userDoc;
    if (docRef == null) return Stream.value([]);
    return docRef
        .collection('mood_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Playtime
  static Future<void> addPlaytime(Duration duration) async {
    final docRef = _userDoc;
    if (docRef == null) return;
    await docRef.set({
      'playtime_seconds': FieldValue.increment(duration.inSeconds),
    }, SetOptions(merge: true));
  }

  static Stream<double> getHoursListenedStream() {
    final docRef = _userDoc;
    if (docRef == null) return Stream.value(0.0);
    return docRef.snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final seconds = (data?['playtime_seconds'] as num?)?.toDouble() ?? 0.0;
      return (seconds / 360.0).ceil() / 10.0;
    });
  }

  static Stream<int> getStreakStream() {
    final docRef = _userDoc;
    if (docRef == null) return Stream.value(0);
    return docRef.snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;

      // Check if streak is still valid (scanned today or yesterday)
      final lastStreakTimestamp = data?['last_streak_date'] as Timestamp?;
      if (lastStreakTimestamp != null) {
        final lastDate = lastStreakTimestamp.toDate();
        final lastStreakDate = DateTime(
          lastDate.year,
          lastDate.month,
          lastDate.day,
        );
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final difference = today.difference(lastStreakDate).inDays;

        if (difference > 1) return 0; // Streak broken
      } else {
        return 0;
      }

      return (data?['current_streak'] as num?)?.toInt() ?? 0;
    });
  }

  static Stream<List<String>> getStreakBadgesStream() {
    return getStreakStream().map((streak) {
      List<String> badges = [];
      if (streak >= 3) badges.add('3 Day Streak 🔥');
      if (streak >= 7) badges.add('7 Day Streak ✨');
      if (streak >= 30) badges.add('30 Day Legend 🏆');
      return badges;
    });
  }
}
