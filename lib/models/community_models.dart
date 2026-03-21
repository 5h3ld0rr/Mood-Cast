import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Tribe {
  final String id;
  final String name;
  final String description;
  final int colorValue;
  final IconData icon;
  final String members;

  Tribe({
    required this.id,
    required this.name,
    required this.description,
    required this.colorValue,
    required this.icon,
    required this.members,
  });

  Color get color => Color(colorValue);

  factory Tribe.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tribe(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      colorValue: data['colorValue'] ?? Colors.blue.toARGB32(),
      icon: IconData(
        data['iconCode'] ?? Icons.group.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      members: data['members'] ?? '0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'colorValue': colorValue,
      'iconCode': icon.codePoint,
      'members': members,
    };
  }
}

class SupportResponse {
  final String userId;
  final String userName;
  final String songTitle;
  final String artist;
  final String? videoId;
  final String? coverUrl;
  final int moodColorValue;
  final DateTime timestamp;

  SupportResponse({
    required this.userId,
    required this.userName,
    required this.songTitle,
    required this.artist,
    this.videoId,
    this.coverUrl,
    required this.moodColorValue,
    required this.timestamp,
  });

  Color get moodColor => Color(moodColorValue);

  factory SupportResponse.fromMap(Map<String, dynamic> data) {
    return SupportResponse(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      songTitle: data['songTitle'] ?? '',
      artist: data['artist'] ?? '',
      videoId: data['videoId'],
      coverUrl: data['coverUrl'],
      moodColorValue: data['moodColorValue'] ?? Colors.blue.toARGB32(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'songTitle': songTitle,
      'artist': artist,
      'videoId': videoId,
      'coverUrl': coverUrl,
      'moodColorValue': moodColorValue,
      'timestamp': timestamp,
    };
  }
}

class CommunityPost {
  final String id;
  final String userId;
  final String userName;
  final String userMood;
  final String content;
  final DateTime timestamp;
  final int moodColorValue;
  final bool isSupportRequest;
  final List<SupportResponse> supportResponses;
  final Map<String, int> reactions;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userMood,
    required this.content,
    required this.timestamp,
    required this.moodColorValue,
    this.isSupportRequest = false,
    this.supportResponses = const [],
    this.reactions = const {
      'Relatable': 0,
      'Vibing': 0,
      'Healing': 0,
      'Powerful': 0,
    },
  });

  Color get moodColor => Color(moodColorValue);

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userMood: data['userMood'] ?? 'Natural',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      moodColorValue: data['moodColorValue'] ?? Colors.blue.toARGB32(),
      isSupportRequest: data['isSupportRequest'] ?? false,
      supportResponses: (data['supportResponses'] as List? ?? [])
          .map((e) => SupportResponse.fromMap(e as Map<String, dynamic>))
          .toList(),
      reactions: Map<String, int>.from(
        data['reactions'] ??
            {'Relatable': 0, 'Vibing': 0, 'Healing': 0, 'Powerful': 0},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userMood': userMood,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'moodColorValue': moodColorValue,
      'isSupportRequest': isSupportRequest,
      'supportResponses': supportResponses.map((e) => e.toMap()).toList(),
      'reactions': reactions,
    };
  }
}

class MoodboardSong {
  final String id;
  final String title;
  final String artist;
  final String? coverUrl;
  final String? videoId;
  final int vibes;
  final String addedBy;
  final String addedById;

  MoodboardSong({
    required this.id,
    required this.title,
    required this.artist,
    this.coverUrl,
    this.videoId,
    this.vibes = 0,
    required this.addedBy,
    required this.addedById,
  });

  factory MoodboardSong.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MoodboardSong(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      coverUrl: data['coverUrl'],
      videoId: data['videoId'],
      vibes: data['vibes'] ?? 0,
      addedBy: data['addedBy'] ?? 'Anonymous',
      addedById: data['addedById'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl,
      'videoId': videoId,
      'vibes': vibes,
      'addedBy': addedBy,
      'addedById': addedById,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
class GlobalMoodStats {
  final int vibingNow;
  final Map<String, int> moodPercentages;
  final Map<String, String> regionalMoods;

  GlobalMoodStats({
    required this.vibingNow,
    required this.moodPercentages,
    required this.regionalMoods,
  });

  factory GlobalMoodStats.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return GlobalMoodStats(
        vibingNow: 12400,
        moodPercentages: {'Happy': 43, 'Natural': 28, 'Sad': 17, 'Angry': 12},
        regionalMoods: {
          'US': 'Happy',
          'EU': 'Sad',
          'ASIA': 'Natural',
          'LA': 'Angry',
          'AF': 'Natural',
        },
      );
    }
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GlobalMoodStats(
      vibingNow: data['vibingNow'] ?? 12400,
      moodPercentages: Map<String, int>.from(data['moodPercentages'] ?? {}),
      regionalMoods: Map<String, String>.from(data['regionalMoods'] ?? {}),
    );
  }
}
