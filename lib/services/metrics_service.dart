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

    // Increment counter
    await docRef.set({
      'scans_completed': FieldValue.increment(1),
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

  static Future<void> incrementScans() async {
    final docRef = _userDoc;
    if (docRef == null) return;
    await docRef.set({
      'scans_completed': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  static Stream<int> getScansCompletedStream() {
    final docRef = _userDoc;
    if (docRef == null) return Stream.value(0);
    return docRef.snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return (data?['scans_completed'] as num?)?.toInt() ?? 0;
    });
  }

  static Future<int> getScansCompleted() async {
    final docRef = _userDoc;
    if (docRef == null) return 0;
    final doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>?;
    return (data?['scans_completed'] as num?)?.toInt() ?? 0;
  }

  // Playtime
  static Future<void> addPlaytime(Duration duration) async {
    final docRef = _userDoc;
    if (docRef == null) return;
    await docRef.set({
      'playtime_seconds': FieldValue.increment(duration.inSeconds),
    }, SetOptions(merge: true));
  }

  static Stream<int> getHoursListenedStream() {
    final docRef = _userDoc;
    if (docRef == null) return Stream.value(0);
    return docRef.snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      final seconds = (data?['playtime_seconds'] as num?)?.toInt() ?? 0;
      return seconds ~/ 3600;
    });
  }

  static Future<int> getHoursListened() async {
    final docRef = _userDoc;
    if (docRef == null) return 0;
    final doc = await docRef.get();
    final data = doc.data() as Map<String, dynamic>?;
    final seconds = (data?['playtime_seconds'] as num?)?.toInt() ?? 0;
    return seconds ~/ 3600;
  }
}
