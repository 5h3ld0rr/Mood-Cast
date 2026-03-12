import 'package:flutter/material.dart';
import '../services/mood_service.dart';
import '../theme.dart';

class MoodBackground extends StatefulWidget {
  final Widget child;
  const MoodBackground({super.key, required this.child});

  @override
  State<MoodBackground> createState() => _MoodBackgroundState();
}

class _MoodBackgroundState extends State<MoodBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: MoodService().currentMood,
      builder: (context, mood, _) {
        final primaryColor = AppTheme.moodColors[mood] ?? AppTheme.primary;
        final bgColor =
            AppTheme.moodBackgrounds[mood] ?? AppTheme.backgroundDark;

        return Stack(
          children: [
            // Base background
            Container(color: bgColor),

            // Animated background elements
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    _buildGlowWidget(
                      top: -100 + (20 * _animation.value),
                      right: -100 + (20 * _animation.value),
                      color: primaryColor.withValues(alpha: 0.3),
                      size: 400,
                    ),
                    _buildGlowWidget(
                      bottom: 50 - (30 * _animation.value),
                      left: -150 + (30 * _animation.value),
                      color: primaryColor.withValues(alpha: 0.15),
                      size: 500,
                    ),
                    if (mood == 'Angry') ...[
                      _buildGlowWidget(
                        top: 200 * _animation.value,
                        left: 100 * _animation.value,
                        color: Colors.purple.withValues(alpha: 0.1),
                        size: 300,
                      ),
                    ],
                    if (mood == 'Happy') ...[
                      _buildGlowWidget(
                        bottom: 0,
                        right: 0,
                        color: Colors.deepPurple.withValues(alpha: 0.1),
                        size: 350,
                      ),
                    ],
                  ],
                );
              },
            ),

            // The actual app content
            // We wrap it in a Theme to provide mood colors to all components
            Theme(data: AppTheme.getThemeForMood(mood), child: widget.child),
          ],
        );
      },
    );
  }

  Widget _buildGlowWidget({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required Color color,
    required double size,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, Colors.transparent],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }
}
