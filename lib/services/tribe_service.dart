import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/tribe_models.dart';
import '../services/player_service.dart';

class TribeService {
  static final TribeService _instance = TribeService._internal();
  factory TribeService() => _instance;
  TribeService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PlayerService _playerService = PlayerService();

  String? get uid => _auth.currentUser?.uid;
  String? get displayName => _auth.currentUser?.displayName ?? 'Anonymous';

  final ValueNotifier<String?> currentTribeIdNotifier = ValueNotifier<String?>(null);
  String? get currentTribeId => currentTribeIdNotifier.value;
  set currentTribeId(String? value) => currentTribeIdNotifier.value = value;
  Timer? _heartbeatTimer;
  StreamSubscription? _sessionSubscription;
  TribeSession? _lastKnownSession;

  /// Returns true if the current user is the DJ of the tribe they are in.
  bool get isDJ {
    if (currentTribeId == null || uid == null) return false;
    return _lastKnownSession?.currentDJUid == uid;
  }

  /// Whether the user is currently in a live tribe session.
  bool get isTribeActive => currentTribeId != null;

  /// Whether the user is blocked from manually controlling playback.
  /// (True for tribe members, False for the DJ and independent users)
  bool get isInteractionLocked => isTribeActive && !isDJ;

  /// Joins a tribe session, enforcing only 1 active tribe per user.
  Future<void> joinTribeSession(String tribeId) async {
    if (uid == null) return;
    
    // Auto-leave current session if trying to join a new one
    if (currentTribeId != null && currentTribeId != tribeId) {
      await leaveTribeSession();
    }

    // Stop any personal track that is currently playing
    await _playerService.stop(isTribeSync: true);

    // Join the session
    await _firestore
        .collection('tribe_sessions')
        .doc(tribeId)
        .collection('members')
        .doc(uid)
        .set({
      'displayName': displayName,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    currentTribeId = tribeId;

    // Start a global listener to keep isDJ and session state fresh across the app
    _sessionSubscription?.cancel();
    _sessionSubscription = getSessionStream(tribeId).listen((session) {
      _lastKnownSession = session;
    });

    // Register a callback: if user manually changes playback, auto-leave tribe
    // UNLESS the user is the DJ, in which case we SYNC the playback to the tribe.
    _playerService.onUserPlaybackAction = () {
      if (currentTribeId != null) {
        if (isDJ) {
          debugPrint('TribeService: DJ triggered playback action – syncing to session.');
          // Use a slight delay to allow the local player state to update first
          Future.delayed(const Duration(milliseconds: 100), () {
            syncPlaybackState(
              isPaused: !_playerService.isPlaying.value,
              positionMs: _playerService.position.value.inMilliseconds,
            );
          });
        } else {
          debugPrint('TribeService: Listener triggered manual playback – auto-leaving tribe.');
          leaveTribeSession();
        }
      }
    };

    // Ensure session doc exists and set DJ if empty
    await _firestore.runTransaction((transaction) async {
      final sessionRef = _firestore.collection('tribe_sessions').doc(tribeId);
      final snapshot = await transaction.get(sessionRef);

      if (!snapshot.exists || snapshot.data()?['currentDJUid'] == null) {
        transaction.set(sessionRef, {
          'currentDJUid': uid,
          'currentDJName': displayName,
          'startTime': DateTime.now().millisecondsSinceEpoch,
          'queue': [],
          'skipVotes': [],
        }, SetOptions(merge: true));
      }
    });

    // Start 15s Heartbeat
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (currentTribeId == null || uid == null) return;
      try {
        await _firestore
            .collection('tribe_sessions')
            .doc(currentTribeId)
            .collection('members')
            .doc(uid)
            .update({'lastSeen': FieldValue.serverTimestamp()});
      } catch (e) {
        debugPrint('Heartbeat failed: $e');
      }
    });
  }

  /// Leaves the current tribe session
  Future<void> leaveTribeSession() async {
    if (uid == null || currentTribeId == null) return;
    
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _sessionSubscription?.cancel();
    _sessionSubscription = null;

    // Unregister the playback hook FIRST to prevent recursive calls
    _playerService.onUserPlaybackAction = null;

    final oldTribeId = currentTribeId!;
    _playerService.stop(isTribeSync: true); // stop tribe music without re-triggering leave

    try {
      // Remove self from members
      await _firestore
          .collection('tribe_sessions')
          .doc(oldTribeId)
          .collection('members')
          .doc(uid)
          .delete();
          
      currentTribeId = null;

      // Check if we were the DJ. If so, resign
      final sessionRef = _firestore.collection('tribe_sessions').doc(oldTribeId);
      final sessionSnap = await sessionRef.get();
      if (sessionSnap.exists && sessionSnap.data()?['currentDJUid'] == uid) {
        await _assignNextDJ(oldTribeId);
      }
    } catch (e) {
      debugPrint('Error leaving tribe: $e');
    }
  }

  /// Called automatically when the DJ leaves. Assigns the next oldest member as DJ.
  Future<void> _assignNextDJ(String tribeId) async {
    final membersSnap = await _firestore
        .collection('tribe_sessions')
        .doc(tribeId)
        .collection('members')
        .orderBy('lastSeen', descending: false)
        .limit(1)
        .get();

    if (membersSnap.docs.isNotEmpty) {
      final nextDJ = membersSnap.docs.first;
      await _firestore.collection('tribe_sessions').doc(tribeId).update({
        'currentDJUid': nextDJ.id,
        'currentDJName': nextDJ.data()['displayName'],
      });
    } else {
      // No one left, clear session
      await _firestore.collection('tribe_sessions').doc(tribeId).update({
        'currentDJUid': null,
        'currentDJName': null,
        'currentTrack': null,
        'queue': [],
        'skipVotes': [],
      });
    }
  }

  /// Take DJ crown manually if the previous DJ died or you want to host an empty room
  Future<void> takeCrown(String tribeId) async {
    if (uid == null) return;
    await _firestore.collection('tribe_sessions').doc(tribeId).update({
      'currentDJUid': uid,
      'currentDJName': displayName,
    });
  }

  /// Stream to listen to real-time session changes (DJ, song, queue, skip votes)
  Stream<TribeSession?> getSessionStream(String tribeId) {
    return _firestore
        .collection('tribe_sessions')
        .doc(tribeId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        _lastKnownSession = TribeSession.fromFirestore(doc);
        return _lastKnownSession;
      }
      return null;
    });
  }

  /// Syncs the current playback state (play/pause/position) to the tribe session.
  /// Only the DJ should call this.
  Future<void> syncPlaybackState({required bool isPaused, int? positionMs}) async {
    if (currentTribeId == null || !isDJ) return;

    final data = {
      'isPaused': isPaused,
      'lastPositionMs': positionMs ?? 0,
    };

    try {
      await _firestore.collection('tribe_sessions').doc(currentTribeId).update(data);
    } catch (e) {
      debugPrint('TribeService: Failed to sync playback state: $e');
    }
  }

  /// Streams active members (seen within the last 45 seconds)
  Stream<List<TribeMember>> getActiveMembersStream(String tribeId) {
    return _firestore
        .collection('tribe_sessions')
        .doc(tribeId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map((doc) => TribeMember.fromFirestore(doc))
          .where((member) => now.difference(member.lastSeen).inSeconds < 45)
          .toList();
    });
  }

  /// Adds a song to the DJ's queue
  Future<void> queueSong(TribeTrack track) async {
    if (currentTribeId == null) return;
    final sessionRef = _firestore.collection('tribe_sessions').doc(currentTribeId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return;

      final session = TribeSession.fromFirestore(snapshot);
      
      if (session.currentTrack == null) {
        // If there is no track playing, play it immediately
        transaction.update(sessionRef, {
          'currentTrack': track.toMap(),
          'startTime': DateTime.now().millisecondsSinceEpoch,
          'isPaused': false,
          'lastPositionMs': 0,
          'skipVotes': [],
        });
      } else {
        // Otherwise queue it
        transaction.update(sessionRef, {
          'queue': FieldValue.arrayUnion([track.toMap()])
        });
      }
    });
  }

  /// Skips the current track and plays the next in the queue.
  /// Used both for skip vote passing and natural track ending.
  Future<void> playNextInQueue() async {
    if (currentTribeId == null) return;
    final sessionRef = _firestore.collection('tribe_sessions').doc(currentTribeId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return;

      final session = TribeSession.fromFirestore(snapshot);
      List<TribeTrack> currentQueue = List.from(session.queue);

      if (currentQueue.isNotEmpty) {
        final nextTrack = currentQueue.removeAt(0);
        transaction.update(sessionRef, {
          'currentTrack': nextTrack.toMap(),
          'queue': currentQueue.map((t) => t.toMap()).toList(),
          'startTime': DateTime.now().millisecondsSinceEpoch,
          'isPaused': false,
          'lastPositionMs': 0,
          'skipVotes': [],
        });
      } else {
        // Queue is empty, clear current track
        transaction.update(sessionRef, {
          'currentTrack': null,
          'startTime': DateTime.now().millisecondsSinceEpoch,
          'skipVotes': [],
        });
      }
    });
  }

  /// Cast a vote to skip the current track
  Future<void> voteSkip() async {
    if (currentTribeId == null || uid == null) return;

    final sessionRef = _firestore.collection('tribe_sessions').doc(currentTribeId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return;

      final session = TribeSession.fromFirestore(snapshot);
      if (session.currentTrack == null) return;

      if (!session.skipVotes.contains(uid)) {
        List<String> newSkipVotes = List.from(session.skipVotes)..add(uid!);
        
        // Count active members to determine 50% majority
        final membersSnap = await _firestore
            .collection('tribe_sessions')
            .doc(currentTribeId)
            .collection('members')
            .get();
        
        final checkTime = DateTime.now();
        int activeCount = 0;
        for (var doc in membersSnap.docs) {
          final lastSeen = (doc.data()['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now();
          if (checkTime.difference(lastSeen).inSeconds < 45) {
            activeCount++;
          }
        }

        // Avoid dividing by zero logic
        if (activeCount == 0) activeCount = 1;

        if (newSkipVotes.length / activeCount >= 0.5) {
          // Majority reached! Skip!
          List<TribeTrack> currentQueue = List.from(session.queue);

          // Give a penalty to the DJ by assigning the crown away? Skip for now, let's just skip song.
          if (currentQueue.isNotEmpty) {
            final nextTrack = currentQueue.removeAt(0);
            transaction.update(sessionRef, {
              'currentTrack': nextTrack.toMap(),
              'queue': currentQueue.map((t) => t.toMap()).toList(),
              'startTime': DateTime.now().millisecondsSinceEpoch,
              'skipVotes': [],
            });
          } else {
            transaction.update(sessionRef, {
              'currentTrack': null,
              'startTime': DateTime.now().millisecondsSinceEpoch,
              'skipVotes': [],
            });
          }
        } else {
          // Just add the vote
          transaction.update(sessionRef, {
            'skipVotes': FieldValue.arrayUnion([uid])
          });
        }
      }
    });
  }

  /// DJ removes a track from line
  Future<void> removeFromQueue(TribeTrack track) async {
    if (currentTribeId == null) return;
    await _firestore.collection('tribe_sessions').doc(currentTribeId).update({
      'queue': FieldValue.arrayRemove([track.toMap()])
    });
  }
}
