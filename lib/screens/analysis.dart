import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme.dart';

class AnalysisScreen extends StatefulWidget {
  final bool isActive;
  const AnalysisScreen({super.key, this.isActive = true});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
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
        ResolutionPreset.medium,
        enableAudio: false,
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

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D121C),
      body: Stack(
        children: [
          // Gradient BG
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF1A2A44), Colors.transparent],
                  stops: [0.0, 0.8],
                  center: Alignment(-0.6, -0.8),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Text(
                        'MoodCast AI Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Camera View
                        Container(
                          width: double.infinity,
                          height: 400,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Camera Preview
                              if (_isCameraInitialized)
                                Positioned.fill(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: CameraPreview(_controller!),
                                  ),
                                ),
                              if (!_isCameraInitialized)
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              // Border Overlays
                              Positioned(
                                top: 16,
                                left: 16,
                                child: _buildCorner(isTop: true, isLeft: true),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: _buildCorner(isTop: true, isLeft: false),
                              ),
                              Positioned(
                                bottom: 16,
                                left: 16,
                                child: _buildCorner(isTop: false, isLeft: true),
                              ),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: _buildCorner(
                                  isTop: false,
                                  isLeft: false,
                                ),
                              ),

                              // Scanning Line
                              Positioned(
                                top: 300,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 2,
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
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Indicator
                              Positioned(
                                bottom: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'LIVE AI SCAN',
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Progress
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text(
                              'Detecting Mood...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '78%',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF192233),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.78,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.gps_fixed,
                                color: AppTheme.primary,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'CURRENT ANALYSIS: FOCUSING',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Alternative Inputs
                        const Text(
                          'ALTERNATIVE INPUTS',
                          style: TextStyle(
                            color: Color(0xFF92A4C9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Voice Analysis
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF192233).withOpacity(0.5),
                            border: Border.all(color: const Color(0xFF232F48)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Voice Analysis',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: List.generate(
                                      8,
                                      (index) => Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        width: 4,
                                        height: [
                                          8.0,
                                          16.0,
                                          24.0,
                                          12.0,
                                          20.0,
                                          8.0,
                                          16.0,
                                          10.0,
                                        ][index],
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.2),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Text Input
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF192233).withOpacity(0.5),
                            border: Border.all(color: const Color(0xFF232F48)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Describe how you feel...',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFF92A4C9),
                                    ),
                                    border: InputBorder.none,
                                    filled: false,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF192233),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.send,
                                  color: AppTheme.primary,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // AI Quick Insights Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary.withOpacity(0.3),
                                const Color(0xFF192233),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.lightbulb,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'AI Quick Insights',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '"Your current focus levels are peaking. This is an ideal window for complex problem-solving or deep learning tasks."',
                                style: TextStyle(
                                  color: Color(0xFF92A4C9),
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
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
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: AppTheme.primary, width: 2)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: AppTheme.primary, width: 2)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: AppTheme.primary, width: 2)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: AppTheme.primary, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }
}
