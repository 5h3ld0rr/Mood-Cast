import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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
  bool _isScanning = false;
  double _progress = 0.0;
  double _zoomScale = 1.3; // Increased base zoom to ensure fill
  String? _detectedMood;


  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
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
        ResolutionPreset.medium, // Better quality within stable limits
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

  void _startScan() async {
    if (_isScanning ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _zoomScale = 1.5;
      _detectedMood = null;
    });

    try {
      // 1. Take a picture for analysis
      final XFile image = await _controller!.takePicture();

      // 2. Simulate progress for UI feel
      for (int i = 0; i <= 40; i += 5) {
        await Future.delayed(const Duration(milliseconds: 50));
        setState(() => _progress = i / 100);
      }

      // 3. Real Mood Detection using ML Kit
      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      String resultMood = 'Natural'; // Default

      if (faces.isNotEmpty) {
        final face = faces.first;
        final smileProb = face.smilingProbability ?? 0.0;
        final leftEyeOpenProb = face.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpenProb = face.rightEyeOpenProbability ?? 1.0;
        final avgEyesOpen = (leftEyeOpenProb + rightEyeOpenProb) / 2;

        debugPrint("ML Kit Analysis: Smile=$smileProb, EyesOpen=$avgEyesOpen");

        if (smileProb > 0.4) {
          resultMood = 'Happy';
        } else if (smileProb < 0.1 && avgEyesOpen < 0.4) {
          resultMood = 'Sad';
        } else if (smileProb < 0.1 && avgEyesOpen > 0.8) {
          resultMood = 'Angry';
        } else {
          resultMood = 'Natural';
        }
      } else {
        resultMood = 'Natural';
      }

      // 4. Continue progress simulation
      for (int i = 45; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 50));
        setState(() => _progress = i / 100);
      }

      setState(() {
        _isScanning = false;
        _zoomScale = 1.3;
        _detectedMood = resultMood;
      });
      MoodService().updateMood(_detectedMood!);
      MetricsService.saveMoodScan(_detectedMood!);
    } catch (e) {
      debugPrint('Error during scan: $e');
      setState(() {
        _isScanning = false;
        _zoomScale = 1.3;
        _detectedMood = 'Natural';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.activeNotifier.removeListener(_handleActiveChange);
    _faceDetector.close();
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final cameraH = screenH * 0.52; // Camera occupies top 52%

    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: Column(
        children: [
          // ─── CAMERA SECTION ───
          SizedBox(
            height: cameraH,
            width: double.infinity,
            child: Stack(
              children: [
                // Camera fill
                if (_isCameraInitialized && _controller != null)
                  Positioned.fill(
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Center(
                            child: Transform.scale(
                              scale: _zoomScale,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height:
                                      constraints.maxWidth /
                                      (_controller!.value.aspectRatio < 1
                                          ? _controller!.value.aspectRatio
                                          : 1 / _controller!.value.aspectRatio),
                                  child: CameraPreview(_controller!),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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

                // Dark gradient at bottom edge (blends into content below)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100, // Taller gradient for smoother blend
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Theme.of(context).canvasColor],
                      ),
                    ),
                  ),
                ),

                // LIVE badge — top left
                Positioned(
                  top: 60,
                  left: 20,
                  child: SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          _PulseCircle(), // New animated pulsing widget
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

                // Title — top center
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
                          style: Theme.of(context).textTheme.titleLarge
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

                // Corner brackets
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

                // Scanning line animation
                if (_isScanning)
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
              ],
            ),
          ),

          // ─── SCROLLABLE CONTENT BELOW CAMERA ───
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Analysis Progress / Results
                  if (_isScanning || _detectedMood != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _detectedMood != null
                              ? 'Mood Analyzed'
                              : 'Scanning Features...',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontSize: 18),
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

                  if (_detectedMood != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                            blurRadius: 30,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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
                                  'CURRENT STATE',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor.withValues(
                                      alpha: 0.6,
                                    ),
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
                    ),
                  if (_detectedMood != null)
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
                              icon: const Icon(
                                Icons.auto_awesome,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'GENERATE VIBE PLAYLIST',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
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
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white70,
                            ),
                            label: const Text(
                              'SCAN AGAIN',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

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

                  if (_detectedMood != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
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
                                : 'AI INSIGHT ✨',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
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
                              fontSize: 16,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(BuildContext context, {required bool isTop, required bool isLeft}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2.5)
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2.5)
              : BorderSide.none,
          left: isLeft
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2.5)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _PulseCircle extends StatefulWidget {
  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(
              alpha: 0.5 + (_pulseController.value * 0.5),
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withValues(
                  alpha: _pulseController.value * 0.8,
                ),
                blurRadius: 8 * _pulseController.value,
                spreadRadius: 2 * _pulseController.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
