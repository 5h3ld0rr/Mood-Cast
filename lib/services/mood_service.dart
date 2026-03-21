import 'package:flutter/foundation.dart';
import 'community_service.dart';

class MoodService {
  static final MoodService _instance = MoodService._internal();
  factory MoodService() => _instance;
  MoodService._internal();

  final ValueNotifier<String> currentMood = ValueNotifier<String>('Happy');
  final CommunityService _communityService = CommunityService();

  void updateMood(String mood) {
    currentMood.value = mood;
    _communityService.updateUserMood(mood);
  }
}
