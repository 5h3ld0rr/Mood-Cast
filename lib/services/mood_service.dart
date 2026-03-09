import 'package:flutter/foundation.dart';

class MoodService {
  static final MoodService _instance = MoodService._internal();
  factory MoodService() => _instance;
  MoodService._internal();

  final ValueNotifier<String> currentMood = ValueNotifier<String>('Happy');

  void updateMood(String mood) {
    currentMood.value = mood;
  }
}

