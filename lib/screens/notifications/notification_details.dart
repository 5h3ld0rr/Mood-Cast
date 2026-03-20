import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final String? id;
  final String title;
  final String body;
  final String? payload;
  final DateTime timestamp;

  const NotificationDetailsScreen({
    super.key,
    this.id,
    required this.title,
    required this.body,
    this.payload,
    required this.timestamp,
  });

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('music') || t.contains('song') || t.contains('playlist')) {
      return Icons.headset;
    } else if (t.contains('account') ||
        t.contains('profile') ||
        t.contains('verify')) {
      return Icons.person;
    } else if (t.contains('subscription') ||
        t.contains('plan') ||
        t.contains('payment')) {
      return Icons.star_rounded;
    } else if (t.contains('analysis') ||
        t.contains('mood') ||
        t.contains('scan')) {
      return Icons.psychology;
    }
    return Icons.notifications_active;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: Stack(
        children: [
          // Dynamic Background Glow
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Icon
                      Center(
                        child: Hero(
                          tag: 'notif_icon_$id',
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: AppTheme.primary.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.2),
                                  blurRadius: 50,
                                  spreadRadius: -20,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getIconForTitle(title),
                              color: AppTheme.primary,
                              size: 56,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Meta Info
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'ACTIVITY REPORT',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd • HH:mm').format(timestamp),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Divider with Glow
                      Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Body
                      Text(
                        body,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 20,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),

                      if (payload != null && payload!.isNotEmpty && payload != '{}') ...[
                        const SizedBox(height: 60),
                        _buildPayloadSection(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildPayloadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              const Text(
                'SYSTEM METADATA',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            payload!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SizedBox(
        height: 64,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
          ),
          child: const Text(
            'UNDERSTOOD',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
          ),
        ),
      ),
    );
  }
}
