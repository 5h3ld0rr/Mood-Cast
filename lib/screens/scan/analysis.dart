import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../theme.dart';

class AnalysisScreen extends StatefulWidget {
  final bool isActive;
  const AnalysisScreen({super.key, this.isActive = true});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isScanning = false;
  bool _isRecording = false;
  double _progress = 0.0;
  double _zoomScale = 1.3; // Increased base zoom to ensure fill
  String? _detectedMood;
  final List<String> _moods = [
    'Happy',
    'Focused',
    'Relaxing',
    'Energetic',
    'Calm',
    'Inspired',
  ];

  late AudioRecorder _audioRecorder;
  double _volumeLevel = 0.0;
  Timer? _recordingTimer;
  final TextEditingController _textController = TextEditingController();
  bool _isTextAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    if (widget.isActive) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(AnalysisScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _disposeCamera();
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

  void _startVoiceAnalysis() async {
    if (_isRecording) return;

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _detectedMood = null;
      _progress = 0.0;
    });

    try {
      // Get temp directory for recording
      final tempDir = await getTemporaryDirectory();
      final path = p.join(
        tempDir.path,
        'voice_scan_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );

      // Start recording to a valid path
      await _audioRecorder.start(const RecordConfig(), path: path);

      // Start volume polling for visualization
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) async {
        final amp = await _audioRecorder.getAmplitude();
        if (mounted) {
          setState(() {
            // Map -60..0 to 0..1
            double level = (amp.current + 60) / 60;
            _volumeLevel = level.clamp(0.1, 1.0);
            _progress = timer.tick / 30; // 3 seconds total (30 ticks)
          });
        }
        if (timer.tick >= 30) {
          _stopVoiceAnalysis();
        }
      });
    } catch (e) {
      debugPrint('Error recording: $e');
      setState(() => _isRecording = false);
    }
  }

  void _stopVoiceAnalysis() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _detectedMood = (_moods..shuffle()).first;
      _progress = 1.0;
    });
  }

  void _startTextAnalysis(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isTextAnalyzing = true;
      _detectedMood = null;
      _progress = 0.0;
    });

    // Simulate analysis progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _progress = i / 100;
      });
    }

    if (!mounted) return;

    setState(() {
      _isTextAnalyzing = false;
      _detectedMood = (_moods..shuffle()).first;
      _textController.clear();
    });
  }

  void _showTextInputDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 30,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F2B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Describe your current vibe in a few words.',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. I feeling really energetic today...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = _textController.text;
                  Navigator.pop(context);
                  _startTextAnalysis(text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'ANALYZE TEXT',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _disposeCamera();
    _audioRecorder.dispose();
    _recordingTimer?.cancel();
    _textController.dispose();
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
                color: AppTheme.primary.withOpacity(0.05),
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
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return AnimatedScale(
                                        scale: _zoomScale,
                                        duration: const Duration(seconds: 1),
                                        curve: Curves.easeInOut,
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: constraints.maxWidth,
                                            height:
                                                constraints.maxWidth /
                                                (_controller!
                                                            .value
                                                            .aspectRatio >
                                                        0
                                                    ? _controller!
                                                          .value
                                                          .aspectRatio
                                                    : 1.0),
                                            child: CameraPreview(_controller!),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                  ),
                                ),

                              // Voice Scan Visualization
                              if (_isRecording)
                                Positioned.fill(
                                  child: Container(
                                    color: Colors.black54,
                                    child: Center(
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: 1.0,
                                          end: 1.0 + (_volumeLevel * 0.5),
                                        ),
                                        duration: const Duration(
                                          milliseconds: 100,
                                        ),
                                        builder: (context, scale, child) {
                                          return Transform.scale(
                                            scale: scale,
                                            child: Container(
                                              width: 120,
                                              height: 120,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.primary
                                                      .withOpacity(0.8),
                                                  width: 2,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primary
                                                        .withOpacity(0.3),
                                                    blurRadius: 20 * scale,
                                                    spreadRadius: 5 * scale,
                                                  ),
                                                ],
                                                color: AppTheme.primary
                                                    .withOpacity(0.2),
                                              ),
                                              child: const Icon(
                                                Icons.mic,
                                                color: Colors.white,
                                                size: 50,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
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
                                    : _isTextAnalyzing
                                    ? 'Analyzing Text...'
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
                            backgroundColor: Colors.white.withOpacity(0.05),
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
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primary.withOpacity(0.3),
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

                        const SizedBox(height: 16),

                        // Alternative Inputs
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputBtn(
                                onTap: _startVoiceAnalysis,
                                icon: _isRecording
                                    ? Icons.stop_circle
                                    : Icons.mic_none,
                                label: 'Voice Scan',
                                active: _isRecording,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputBtn(
                                onTap: _showTextInputDialog,
                                icon: Icons.text_fields_outlined,
                                label: 'Text Input',
                                active: _isTextAnalyzing,
                              ),
                            ),
                          ],
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

  Widget _buildInputBtn({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primary.withOpacity(0.1)
              : const Color(0xFF192233),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: active ? AppTheme.primary : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: active ? AppTheme.primary : Colors.white60,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? AppTheme.primary : Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
