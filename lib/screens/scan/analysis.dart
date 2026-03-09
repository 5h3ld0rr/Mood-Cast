import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../../theme.dart';

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
  final List<String> _moods = ['Happy', 'Angry', 'Sad', 'Natural'];

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
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _progress = 0.0;
      _zoomScale = 1.5; // Moderate scan zoom
      _detectedMood = null;
    });

    // Simulate progress
    for (int i = 0; i <= 100; i += 2) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        _progress = i / 100;
      });
    }

    setState(() {
      _isScanning = false;
      _zoomScale = 1.3; // Return to base zoom
      _detectedMood = (_moods..shuffle()).first;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.activeNotifier.removeListener(_handleActiveChange);
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D121C),
      body: Stack(
        children: [
          // Background Gradient blur
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'MoodCast AI Analysis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // The Scanning Box (Camera constrained here)
                        Container(
                          width: double.infinity,
                          height: 400,
                          decoration: BoxDecoration(
                            color: Colors
                                .transparent, // Background borders removed
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // 1. Camera Preview (Full Fill - No Borders)
                              if (_isCameraInitialized && _controller != null)
                                Positioned.fill(
                                  child: ClipRect(
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Calculate scale to fill the container perfectly
                                        final double containerWidth =
                                            constraints.maxWidth;
                                        final double containerHeight =
                                            constraints.maxHeight;

                                        // Camera aspect ratio is typically width/height of the SENSOR
                                        // In portrait, we usually need the inverse if it's not handled.
                                        final double cameraAspectRatio =
                                            _controller!.value.aspectRatio;

                                        // Effective aspect ratio in portrait
                                        double scale = 1.0;
                                        final double containerAspectRatio =
                                            containerWidth / containerHeight;

                                        if (containerAspectRatio >
                                            cameraAspectRatio) {
                                          scale =
                                              containerAspectRatio /
                                              cameraAspectRatio;
                                        } else {
                                          scale =
                                              cameraAspectRatio /
                                              containerAspectRatio;
                                        }

                                        return AnimatedScale(
                                          scale: scale * _zoomScale,
                                          duration: const Duration(seconds: 1),
                                          curve: Curves.easeInOut,
                                          alignment: Alignment.center,
                                          child: Center(
                                            child: AspectRatio(
                                              aspectRatio: cameraAspectRatio,
                                              child: CameraPreview(
                                                _controller!,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              else
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                ),

                              // 2. Corners (Positioned exactly at edges 0,0)
                              Positioned(
                                top: 0,
                                left: 0,
                                child: _buildCorner(isTop: true, isLeft: true),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: _buildCorner(isTop: true, isLeft: false),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: _buildCorner(isTop: false, isLeft: true),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: _buildCorner(
                                  isTop: false,
                                  isLeft: false,
                                ),
                              ),

                              // 3. Scanning Animation (Constrained inside box)
                              if (_isScanning)
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 10.0, end: 390.0),
                                  duration: const Duration(seconds: 2),
                                  builder: (context, value, child) {
                                    return Positioned(
                                      top: value,
                                      left: 20,
                                      right: 20,
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              AppTheme.primary,
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: AppTheme.primary,
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // 4. Indicator
                              Positioned(
                                bottom: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'LIVE AI SCAN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Analysis Progress / Results
                        if (_isScanning || _detectedMood != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _detectedMood != null
                                    ? 'Mood Detected!'
                                    : 'Analyzing Face...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.05,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 20),
                        ],

                        if (_detectedMood != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'VIBE CHECKED',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _detectedMood!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                                  AppTheme.primary.withValues(alpha: 0.1),
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
                                  _detectedMood == 'Angry' ||
                                          _detectedMood == 'Sad'
                                      ? 'CHEER UP JOKE! 😂'
                                      : 'AI INSIGHT ✨',
                                  style: TextStyle(
                                    color: AppTheme.primary.withValues(
                                      alpha: 0.5,
                                    ),
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

                        const SizedBox(height: 30),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'OR SELECT YOUR MOOD',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _moods.map((mood) {
                              final isSelected = _detectedMood == mood;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _detectedMood = mood;
                                      _progress = 1.0;
                                      _isScanning = false;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : Colors.white.withValues(
                                              alpha: 0.05,
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _moodEmojis[mood]!,
                                          style: const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          mood,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppTheme.primary, width: 3)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppTheme.primary, width: 3)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppTheme.primary, width: 3)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppTheme.primary, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}
