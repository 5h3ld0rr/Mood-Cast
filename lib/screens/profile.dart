import 'package:flutter/material.dart';
import '../theme.dart';
import 'login.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF1A3A5F), Colors.transparent],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF0D1526), Colors.transparent],
                  stops: [0.0, 0.5],
                ),
              ),
            ),
          ),
          SafeArea(
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
                  actions: [],
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Avatar
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.5),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.2),
                                blurRadius: 24,
                                spreadRadius: 4,
                              ),
                            ],
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=400&auto=format&fit=crop',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Alex Johnson',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '@alexj_music',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem('342', 'Hours Listened'),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            _buildStatItem('89', 'Scans Completed'),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            _buildStatItem('12', 'Playlists'),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Menu Items
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.person_outline,
                                title: 'Edit Profile',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.notifications_none,
                                title: 'Notifications',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.security,
                                title: 'Privacy & Security',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.subscriptions_outlined,
                                title: 'Subscription',
                                subtitle: 'Pro Plan Active',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuItem(
                                icon: Icons.help_outline,
                                title: 'Help & Support',
                                onTap: () {},
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
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (r) => false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: BorderSide(
                                color: Colors.redAccent.withOpacity(0.5),
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
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 24),
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
              style: const TextStyle(color: AppTheme.primary, fontSize: 12),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.05),
      indent: 64,
    );
  }
}
