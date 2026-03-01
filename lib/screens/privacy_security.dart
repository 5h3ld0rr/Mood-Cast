import 'package:flutter/material.dart';
import '../theme.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _dataCollection = true;
  bool _personalizedAds = false;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('SECURITY'),
            const SizedBox(height: 16),
            _buildSettingsContainer([
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  _showSnackBar('Password reset link sent to your email.');
                },
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('PRIVACY'),
            const SizedBox(height: 16),
            _buildSettingsContainer([
              _buildSettingsTile(
                icon: Icons.analytics_outlined,
                title: 'Data Collection',
                subtitle: 'Help improve MoodCast by sharing usage data',
                trailing: Switch(
                  value: _dataCollection,
                  onChanged: (value) {
                    setState(() => _dataCollection = value);
                    _showSnackBar(
                      value
                          ? 'Data collection enabled'
                          : 'Data collection disabled',
                    );
                  },
                  activeColor: AppTheme.primary,
                ),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.ads_click,
                title: 'Personalized Recommendations',
                trailing: Switch(
                  value: _personalizedAds,
                  onChanged: (value) {
                    setState(() => _personalizedAds = value);
                    _showSnackBar(
                      value
                          ? 'Personalized ads enabled'
                          : 'Personalized ads disabled',
                    );
                  },
                  activeColor: AppTheme.primary,
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('ACCOUNT DELETION'),
            const SizedBox(height: 16),
            _buildSettingsContainer([
              _buildSettingsTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                titleColor: Colors.redAccent,
                onTap: () {
                  _showDeleteConfirmation(context);
                },
              ),
            ]),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color titleColor = Colors.white,
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
        style: TextStyle(
          color: titleColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            )
          : null,
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
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

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(
                'Account deletion request submitted.',
                isError: true,
              );
            },
            child: const Text(
              'DELETE',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
