import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStats {
  final double hoursListened;
  final int streak;
  final int points;

  UserStats({
    required this.hoursListened,
    required this.streak,
    required this.points,
  });
}

class MetricsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static DocumentReference? get _userDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  // Scans
  static Future<void> saveMoodScan(
    String mood, {
    Map<String, double>? confidence,
  }) async {
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
      'confidence': confidence,
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

  static Stream<UserStats> getUserStatsStream() {
    final docRef = _userDoc;
    if (docRef == null) {
      return Stream.value(UserStats(hoursListened: 0, streak: 0, points: 0));
    }

    return docRef.snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;

      // 1. Calculate Playtime HOURS
      final seconds = (data?['playtime_seconds'] as num?)?.toDouble() ?? 0.0;
      final hours = (seconds / 360.0).ceil() / 10.0;

      // 2. Calculate Valid Streak
      int streak = (data?['current_streak'] as num?)?.toInt() ?? 0;
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
        if (difference > 1) streak = 0;
      } else {
        streak = 0;
      }

      // 3. Points
      final points = (data?['moodPoints'] as num?)?.toInt() ?? 0;

      return UserStats(hoursListened: hours, streak: streak, points: points);
    });
  }
}
