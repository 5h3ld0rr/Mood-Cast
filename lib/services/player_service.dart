import 'dart:async';
import 'package:flutter/material.dart';

class SongInfo {
  final String title;
  final String artist;
  final String? coverUrl;

  SongInfo({required this.title, required this.artist, this.coverUrl});
}

class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final ValueNotifier<SongInfo?> currentSong = ValueNotifier<SongInfo?>(null);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> isLiked = ValueNotifier<bool>(false);

  Timer? _timer;

  void play(SongInfo song) {
    currentSong.value = song;
    isPlaying.value = true;
    progress.value = 0.0;
    isLiked.value = false; // Mock: reset for new song
    _startTimer();
  }

  void toggleLiked() {
    isLiked.value = !isLiked.value;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isPlaying.value) {
        progress.value = (progress.value + 0.001) % 1.0;
      }
    });
  }

  void togglePlay() {
    isPlaying.value = !isPlaying.value;
    if (isPlaying.value) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void stop() {
    _timer?.cancel();
    isPlaying.value = false;
    currentSong.value = null;
    progress.value = 0.0;
  }
}
