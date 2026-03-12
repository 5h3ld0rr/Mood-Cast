import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../auth/login.dart';
import 'edit_profile.dart';
import 'privacy_security.dart';
import 'subscription.dart';
import 'help_support.dart';
import 'insights/insights.dart';
import '../../services/player_service.dart';
import '../../widgets/cached_image.dart';
import '../../services/database_service.dart';
import '../../services/metrics_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  void _refreshProfile() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              floating: true,
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: const [],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StreamBuilder<User?>(
                      stream: _authService.userChanges,
                      builder: (context, snapshot) {
                        final user =
                            snapshot.data ?? _authService.currentUser;
                        final photoUrl = user?.photoURL;
                        final displayName = user?.displayName ?? 'User';
                        final email = user?.email ?? 'No email';

                        return Column(
                          children: [
                            // Profile Avatar
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: CachedImage(
                                imageUrl:
                                    photoUrl != null && photoUrl.isNotEmpty
                                    ? photoUrl
                                    : 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTmn4pWrDE1f07NiO_-ALAPW18mUchf6vj9oA&s',
                                isCircle: true,
                                width: 120,
                                height: 120,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color ??
                                    AppTheme.textMuted,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StreamBuilder<int>(
                          stream: MetricsService.getHoursListenedStream(),
                          builder: (context, snapshot) {
                            return _buildStatItem(
                              (snapshot.data ?? 0).toString(),
                              'Hours Listened',
                            );
                          },
                        ),
                        _buildVerticalDivider(),
                        StreamBuilder<int>(
                          stream: MetricsService.getScansCompletedStream(),
                          builder: (context, snapshot) {
                            return _buildStatItem(
                              (snapshot.data ?? 0).toString(),
                              'Scans Done',
                            );
                          },
                        ),
                        _buildVerticalDivider(),
                        StreamBuilder<int>(
                          stream: MetricsService.getStreakStream(),
                          builder: (context, snapshot) {
                            return _buildStatItem(
                              '${snapshot.data ?? 0}🔥',
                              'Streak',
                            );
                          },
                        ),
                        _buildVerticalDivider(),
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: DatabaseService().getPlaylists(),
                          builder: (context, snapshot) {
                            final count = snapshot.data?.length ?? 0;
                            return _buildStatItem(
                              count.toString(),
                              'Playlists',
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Streak Badges
                    StreamBuilder<List<String>>(
                      stream: MetricsService.getStreakBadgesStream(),
                      builder: (context, snapshot) {
                        final badges = snapshot.data ?? [];
                        if (badges.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: badges.map((badge) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    badge,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

                    // Menu Items
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            onTap: () async {
                              final result =
                                  await Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfileScreen(),
                                    ),
                                  );
                              if (result == true) {
                                _refreshProfile();
                              }
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.high_quality,
                            title: 'Audio Quality',
                            trailing: ValueListenableBuilder<AudioQuality>(
                              valueListenable: PlayerService().audioQuality,
                              builder: (context, quality, _) {
                                String label = 'Normal';
                                if (quality == AudioQuality.low) {
                                  label = 'Data Saver';
                                }
                                if (quality == AudioQuality.high) {
                                  label = 'High Quality';
                                }
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyMedium?.color ??
                                            AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                                          AppTheme.textMuted,
                                    ),
                                  ],
                                );
                              },
                            ),
                            onTap: _showAudioQualityDialog,
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.insights,
                            title: 'Trends & Insights',
                            onTap: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const InsightsScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.security,
                            title: 'Privacy & Security',
                            onTap: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacySecurityScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.subscriptions_outlined,
                            title: 'Subscription',
                            subtitle: 'Free Plan Active',
                            onTap: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SubscriptionScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            onTap: () {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const HelpSupportScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Log Out Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () async {
                          await _authService.signOut();
                          if (context.mounted) {
                            Navigator.of(
                              context,
                              rootNavigator: true,
                            ).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (r) => false,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'LOG OUT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8) ??
                  const Color(0xFF94A3B8), // Slate-400
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12),
            )
          : null,
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color ?? AppTheme.textMuted),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
      indent: 64,
    );
  }

  void _showAudioQualityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).canvasColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
          ),
          title: const Text(
            'Audio Quality',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQualityOption(
                AudioQuality.low,
                'Data Saver',
                'Lowest bitrate',
              ),
              _buildQualityOption(
                AudioQuality.medium,
                'Normal',
                'Standard bitrate',
              ),
              _buildQualityOption(
                AudioQuality.high,
                'High Quality',
                'Highest bitrate, uses more data',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityOption(
    AudioQuality value,
    String title,
    String subtitle,
  ) {
    return ValueListenableBuilder<AudioQuality>(
      valueListenable: PlayerService().audioQuality,
      builder: (context, currentQuality, _) {
        return RadioListTile<AudioQuality>(
          value: value,
          groupValue: currentQuality,
          activeColor: Theme.of(context).primaryColor,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color ??
                  AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          onChanged: (val) {
            if (val != null) {
              PlayerService().setAudioQuality(val);
              Navigator.pop(context);
            }
          },
        );
      },
    );
  }
}
