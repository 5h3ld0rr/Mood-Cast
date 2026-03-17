import 'package:cloud_firestore/cloud_firestore.dart';

class TribeTrack {
  final String id;
  final String title;
  final String artist;
  final String? coverUrl;
  final String addedBy; // Username of the DJ who added it
  final String videoId;

  TribeTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.coverUrl,
    required this.addedBy,
    required this.videoId,
  });

  factory TribeTrack.fromMap(Map<String, dynamic> data) {
    return TribeTrack(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      coverUrl: data['coverUrl'],
      addedBy: data['addedBy'] ?? '',
      videoId: data['videoId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl,
      'addedBy': addedBy,
      'videoId': videoId,
    };
  }
}

class TribeSession {
  final String tribeId;
  final String? currentDJUid;
  final String? currentDJName;
  final TribeTrack? currentTrack;
  final int startTime; // Epoch milliseconds, so everyone syncs
  final List<TribeTrack> queue;
  final List<String> skipVotes; // UIDs of people who voted to skip

  TribeSession({
    required this.tribeId,
    this.currentDJUid,
    this.currentDJName,
    this.currentTrack,
    this.startTime = 0,
    this.queue = const [],
    this.skipVotes = const [],
  });

  factory TribeSession.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return TribeSession(
      tribeId: doc.id,
      currentDJUid: data['currentDJUid'],
      currentDJName: data['currentDJName'],
      currentTrack: data['currentTrack'] != null
          ? TribeTrack.fromMap(Map<String, dynamic>.from(data['currentTrack']))
          : null,
      startTime: data['startTime'] ?? 0,
      queue: (data['queue'] as List<dynamic>? ?? [])
          .map((e) => TribeTrack.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      skipVotes: List<String>.from(data['skipVotes'] ?? []),
    );
  }
}

class TribeMember {
  final String uid;
  final String displayName;
  final DateTime lastSeen;

  TribeMember({
    required this.uid,
    required this.displayName,
    required this.lastSeen,
  });

  factory TribeMember.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return TribeMember(
      uid: doc.id,
      displayName: data['displayName'] ?? 'Listener',
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
