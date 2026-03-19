import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../theme.dart';
import '../../services/mood_service.dart';
import '../../services/metrics_service.dart';
import '../home/recommendations.dart';

class AnalysisScreen extends StatefulWidget {
  final ValueNotifier<bool> activeNotifier;
  const AnalysisScreen({super.key, required this.activeNotifier});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  Face? _detectedFace;
  bool _isScanning = false;
  double _progress = 0.0;
  double _zoomScale = 1.3;
  String? _detectedMood;
  Map<String, double> _confidenceScores = {};
  int _simulatedHeartRate = 0;
  Timer? _hrTimer;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  final Map<String, String> _moodEmojis = {
    'Happy': '😊',
    'Angry': '😠',
    'Sad': '😔',
    'Natural': '😐',
  };

  final List<String> _happyPhrases = [
    "You look radiant! Keep that positive energy flowing throughout your day.",
    "That's a million-dollar smile! You're lighting up the room.",
    "Happiness looks great on you! Stay positive and keep shining.",
    "Vibe check: 100% Pure Joy. Have an amazing day ahead!",
  ];

  final List<String> _naturalPhrases = [
    "A balanced state of mind. Perfect for staying grounded and focused.",
    "Stay calm and keep moving. You're in a great space to explore new rhythms.",
    "The perfect neutral zone. Your mind is clear and ready for anything.",
    "Finding your center is key. You look perfectly poised and steady.",
  ];

  final List<String> _angryJokes = [
    "Chill bro! Don't let your anger control you. Remember, when you're angry, you look like a pufferfish! 🐡",
    "Relax! Why so serious? If you're angry with the world, remember that it's the only place with pizza. 🍕",
    "Feeling hot? Cool down! Did you know that anger is just one letter away from D-anger? ⚠️",
    "Anger is like a storm, but remember, every storm runs out of rain. Stay cool! 🧊",
  ];

  final List<String> _sadJokes = [
    "Turn that frown upside down! Why was the math book sad? Because it had too many problems. 📚",
    "Smile! Did you know that it takes 17 muscles to smile and 43 to frown? Save energy, just smile! 😊",
    "Don't be sad! I asked my dog what's two minus two. He said nothing. 🐕",
    "Life is like a mirror, it smiles back when you smile at it. Give it a try! ✨",
  ];

  String _getMoodContent(String mood) {
    if (mood == 'Angry') return (_angryJokes..shuffle()).first;
    if (mood == 'Sad') return (_sadJokes..shuffle()).first;
    if (mood == 'Happy') return (_happyPhrases..shuffle()).first;
    if (mood == 'Natural') return (_naturalPhrases..shuffle()).first;
    return "";
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.activeNotifier.addListener(_handleActiveChange);

    if (widget.activeNotifier.value) {
      _initializeCamera();
    }
  }

  void _handleActiveChange() {
    if (widget.activeNotifier.value) {
      _initializeCamera();
    } else {
      _disposeCamera();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_controller != null && _controller!.value.isInitialized) {
        _disposeCamera();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (widget.activeNotifier.value) {
        _initializeCamera();
      }
    }
  }

  @override
  void didUpdateWidget(AnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeNotifier != widget.activeNotifier) {
      oldWidget.activeNotifier.removeListener(_handleActiveChange);
      widget.activeNotifier.addListener(_handleActiveChange);
      _handleActiveChange();
    }
  }

  Future<void> _disposeCamera() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraInitialized || _controller != null) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      CameraDescription? camera;
      for (var c in cameras) {
        if (c.lensDirection == CameraLensDirection.front) {
          camera = c;
          break;
        }
      }
      camera ??= cameras.first;

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startHeartRateSimulation() {
    _hrTimer?.cancel();
    _hrTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted && _isScanning) {
        setState(() {
          _simulatedHeartRate = 65 + (DateTime.now().millisecond % 15);
        });
      }
    });
  }

  void _startScan() async {
    if (_isScanning ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _zoomScale = 1.5;
      _detectedFace = null;
      _detectedMood = null;
      _confidenceScores = {};
      _simulatedHeartRate = 72;
    });

    _startHeartRateSimulation();
    
    // Phase 1: Locking Phase with Haptics and Zoom
    HapticFeedback.vibrate();
    
    try {
      final XFile image = await _controller!.takePicture();

      for (int i = 0; i <= 40; i += 4) {
        await Future.delayed(const Duration(milliseconds: 60));
        setState(() => _progress = i / 100);
        if (i % 12 == 0) HapticFeedback.lightImpact();
      }

      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      String resultMood = 'Natural';
      Map<String, double> scores = {
        'Happy': 0.1,
        'Sad': 0.1,
        'Angry': 0.1,
        'Natural': 0.7,
      };

      if (faces.isNotEmpty) {
        final face = faces.first;
        _detectedFace = face;
        final smileProb = face.smilingProbability ?? 0.0;
        final leftEyeOpenProb = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpenProb = face.rightEyeOpenProbability ?? 1.0;
        final avgEyesOpen = (leftEyeOpenProb + rightEyeOpenProb) / 2;

        if (smileProb > 0.4) {
          resultMood = 'Happy';
          scores = {
            'Happy': (smileProb * 0.9).clamp(0.6, 0.95),
            'Natural': (1 - smileProb).clamp(0.05, 0.3),
            'Sad': 0.02,
            'Angry': 0.03,
          };
        } else if (smileProb < 0.1 && avgEyesOpen < 0.4) {
          resultMood = 'Sad';
          scores = {
            'Sad': 0.85,
            'Natural': 0.1,
            'Happy': 0.01,
            'Angry': 0.04,
          };
        } else if (smileProb < 0.1 && avgEyesOpen > 0.8) {
          resultMood = 'Angry';
          scores = {
            'Angry': 0.8,
            'Natural': 0.15,
            'Sad': 0.03,
            'Happy': 0.02,
          };
        } else {
          resultMood = 'Natural';
          scores = {
            'Natural': 0.85,
            'Happy': 0.05,
            'Sad': 0.05,
            'Angry': 0.05,
          };
        }
      }

      for (int i = 45; i <= 100; i += 8) {
        await Future.delayed(const Duration(milliseconds: 50));
        setState(() => _progress = i / 100);
      }

      _hrTimer?.cancel();
      HapticFeedback.heavyImpact();

      setState(() {
        _isScanning = false;
        _zoomScale = 1.3;
        _detectedMood = resultMood;
        _confidenceScores = scores;
      });
      MoodService().updateMood(_detectedMood!);
      MetricsService.saveMoodScan(_detectedMood!, confidence: _confidenceScores);
    } catch (e) {
      debugPrint('Error during scan: $e');
      _hrTimer?.cancel();
      setState(() {
        _isScanning = false;
        _zoomScale = 1.3;
        _detectedMood = 'Natural';
      });
    }
  }

  Widget _buildManualMoodSync() {
    final moods = ['Happy', 'Sad', 'Angry', 'Natural'];
    final icons = {
      'Happy': Icons.wb_sunny_rounded,
      'Sad': Icons.cloudy_snowing,
      'Angry': Icons.bolt_rounded,
      'Natural': Icons.spa_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          'MANUAL MOOD SYNC',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<String>(
          valueListenable: MoodService().currentMood,
          builder: (context, currentMood, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: moods.map((mood) {
                final isSelected = currentMood == mood;
                final color = AppTheme.moodColors[mood] ?? Colors.white;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _detectedMood = mood;
                      _progress = 1.0;
                      _isScanning = false;
                      _confidenceScores = {
                        mood: 1.0,
                        if (mood != 'Happy') 'Happy': 0.0,
                        if (mood != 'Sad') 'Sad': 0.0,
                        if (mood != 'Angry') 'Angry': 0.0,
                        if (mood != 'Natural') 'Natural': 0.0,
                      };
                    });
                    MoodService().updateMood(mood);
                    MetricsService.saveMoodScan(mood, confidence: _confidenceScores);
                    HapticFeedback.mediumImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icons[mood],
                          color: isSelected ? color : Colors.white38,
                          size: 18,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Text(
                            mood.toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.activeNotifier.removeListener(_handleActiveChange);
    _faceDetector.close();
    _disposeCamera();
    _hrTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final cameraH = screenH * 0.52;

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: Column(
        children: [
          SizedBox(
            height: cameraH,
            width: double.infinity,
            child: Stack(
              children: [
                if (_isCameraInitialized && _controller != null)
                  Positioned.fill(
                    child: Stack(
                      children: [
                        // Lens Iris Mask
                        Center(
                          child: ClipPath(
                            clipper: _LensClipper(),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Transform.scale(
                                  scale: _zoomScale,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      height: constraints.maxWidth /
                                          (_controller!.value.aspectRatio < 1
                                              ? _controller!.value.aspectRatio
                                              : 1 /
                                                  _controller!
                                                      .value.aspectRatio),
                                      child: CameraPreview(_controller!),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Circular Lens HUD & Border
                        Center(
                          child: _LensHUD(
                            isScanning: _isScanning,
                            progress: _progress,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    color: Theme.of(context).canvasColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context).canvasColor,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 20,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          _PulseCircle(),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE AI ANALYSIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(
                          'SCANNING',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontSize: 14,
                                letterSpacing: 4,
                                color: Colors.white38,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 80,
                  left: 20,
                  child: _buildCorner(context, isTop: true, isLeft: true),
                ),
                Positioned(
                  top: 80,
                  right: 20,
                  child: _buildCorner(context, isTop: true, isLeft: false),
                ),
                Positioned(
                  bottom: 80,
                  left: 20,
                  child: _buildCorner(context, isTop: false, isLeft: true),
                ),
                Positioned(
                  bottom: 80,
                  right: 20,
                  child: _buildCorner(context, isTop: false, isLeft: false),
                ),
                if (_isScanning) ...[
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 85.0, end: cameraH - 90),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Positioned(
                        top: value,
                        left: 40,
                        right: 40,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Theme.of(context).primaryColor,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).primaryColor,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  ..._buildNeuralNodes(cameraH),
                  Positioned(
                    right: 20,
                    top: 150,
                    child: _buildBioDataOverlay(),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  if (_isScanning || _detectedMood != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _detectedMood != null
                              ? 'Mood Analyzed'
                              : 'Scanning Features...',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 18),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_detectedMood != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.05),
                            blurRadius: 30,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Theme.of(context).primaryColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PRIMARY EMOTION',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.6),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _detectedMood!.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -1,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_confidenceScores.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _buildMoodBreakdown(),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecommendationsScreen(
                                      mood: _detectedMood,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.auto_awesome,
                                  color: Colors.black),
                              label: const Text(
                                'GENERATE VIBE PLAYLIST',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _detectedMood = null;
                                _progress = 0.0;
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white70),
                            label: const Text(
                              'SCAN AGAIN',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _moodEmojis[_detectedMood]!,
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _detectedMood == 'Angry' || _detectedMood == 'Sad'
                                ? 'CHEER UP JOKE! 😂'
                                : 'MOOD INSIGHT ✨',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getMoodContent(_detectedMood!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                  if (!_isScanning && _detectedMood == null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'START AI SCAN',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  _buildManualMoodSync(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioDataOverlay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildBioRow('BPM', '$_simulatedHeartRate', Icons.favorite),
        const SizedBox(height: 12),
        _buildBioRow('CHNL', 'SYNC_09', Icons.hub_rounded),
        const SizedBox(height: 12),
        _buildBioRow('EYE_P', 'ACTIVE', Icons.visibility_rounded),
      ],
    );
  }

  Widget _buildBioRow(String label, String value, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                icon,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.8),
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNeuralNodes(double cameraH) {
    if (!_isScanning) return [];
    
    return [
      CustomPaint(
        size: Size(double.infinity, cameraH),
        painter: _NeuralConnectionPainter(
          progress: _progress,
          color: Theme.of(context).primaryColor,
          face: _detectedFace,
        ),
      ),
    ];
  }

  Widget _buildMoodBreakdown() {
    return Column(
      children: _confidenceScores.entries.map((e) {
        if (e.value < 0.05) return const SizedBox.shrink();
        final color = AppTheme.moodColors[e.key] ?? Colors.white;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key.toUpperCase(),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${(e.value * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    height: 6,
                    width: MediaQuery.of(context).size.width * 0.7 * e.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.3), color],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCorner(BuildContext context,
      {required bool isTop, required bool isLeft}) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  width: 3)
              : BorderSide.none,
          left: isLeft
              ? BorderSide(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  width: 3)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                  width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _LensClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: (size.width / 2) * 0.85,
      ));
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LensHUD extends StatefulWidget {
  final bool isScanning;
  final double progress;

  const _LensHUD({required this.isScanning, required this.progress});

  @override
  State<_LensHUD> createState() => _LensHUDState();
}

class _LensHUDState extends State<_LensHUD> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    final size = MediaQuery.of(context).size.width;
    final radius = (size / 2) * 0.85;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Rotating HUD
          RotationTransition(
            turns: _rotationController,
            child: CustomPaint(
              size: Size(radius * 2.4, radius * 2.4),
              painter: _HUDPainter(color: color.withValues(alpha: 0.3)),
            ),
          ),
          // Inner Glowing Border
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isScanning ? color : color.withValues(alpha: 0.4),
                width: widget.isScanning ? 4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: widget.isScanning ? 0.6 : 0.2),
                  blurRadius: widget.isScanning ? 25 : 15,
                  spreadRadius: widget.isScanning ? 5 : 2,
                ),
              ],
            ),
          ),
          if (widget.isScanning)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Container(
                  width: radius * 2.1,
                  height: radius * 2.1,
                  child: CircularProgressIndicator(
                    value: widget.progress,
                    strokeWidth: 2,
                    color: color,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HUDPainter extends CustomPainter {
  final Color color;
  _HUDPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 4 dashed arcs
    for (int i = 0; i < 4; i++) {
      final startAngle = (i * 90 + 10) * (math.pi / 180);
      const sweepAngle = 70 * (math.pi / 180);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Draw small ticks
    for (int i = 0; i < 24; i++) {
      final angle = (i * 15) * (math.pi / 180);
      final p1 = Offset(
        center.dx + (radius - 5) * math.cos(angle),
        center.dy + (radius - 5) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius + 5) * math.cos(angle),
        center.dy + (radius + 5) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NeuralConnectionPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Face? face;

  _NeuralConnectionPainter({
    required this.progress,
    required this.color,
    this.face,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < 0.1) return;

    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress).clamp(0, 1) * 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final random = math.Random(42);
    final points = List.generate(15, (index) {
      return Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
    });

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final dist = (points[i] - points[j]).distance;
        if (dist < 150 && random.nextDouble() > 0.5) {
          canvas.drawLine(points[i], points[j], paint);
        }
      }
    }
    
    // Draw dots at points
    final dotPaint = Paint()..color = color.withValues(alpha: 0.6);
    for (var p in points) {
      canvas.drawCircle(p, 2 * (1 + progress), dotPaint);
    }

    // Highlight face if detected (simulate landmark connections)
    if (face != null && progress > 0.4) {
      final facePaint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      
      // Map ML Kit coordinates to preview size (simplified)
      final previewRect = Rect.fromLTWH(
        size.width * 0.2, 
        size.height * 0.2, 
        size.width * 0.6, 
        size.height * 0.4
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(previewRect, const Radius.circular(20)), 
        facePaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PulseCircle extends StatefulWidget {
  @override
  _PulseCircleState createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: _controller.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: _controller.value * 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
