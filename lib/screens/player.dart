import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../utils/ui_utils.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F18),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A2333), Color(0xFF101827), Color(0xFF0A0F18)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
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
                          const SizedBox(width: 48),
                          const Text(
                            'Wellness Player',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            color: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'playlist':
                                  _showAddedToPlaylist();
                                  break;
                                case 'sleep':
                                  _showSleepTimerDialog();
                                  break;
                                case 'share':
                                  _handleShare();
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'playlist',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.playlist_add,
                                      size: 20,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Add to Playlist',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'sleep',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 20,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Sleep Timer',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'share',
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.share_outlined,
                                      size: 20,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Share',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Mood Badge
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.emergency,
                                color: AppTheme.primary,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'CURRENT MOOD: STRESSED • ANXIOUS',
                                style: TextStyle(
                                  color: AppTheme.primary,
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

                    // Animation Area
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Container(
                                    width:
                                        256 + 20 * _animationController.value,
                                    height:
                                        256 + 20 * _animationController.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withOpacity(
                                            0.3 * _animationController.value,
                                          ),
                                          blurRadius: 40,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              Container(
                                width: 192,
                                height: 192,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                              ),
                              Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.4),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.air,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'DEEP CALM',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),
                          const Text(
                            'Guided Breathing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Inhale',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('•', style: TextStyle(color: Colors.grey)),
                              SizedBox(width: 8),
                              Text(
                                'Hold',
                                style: TextStyle(color: Colors.grey),
                              ),
                              SizedBox(width: 8),
                              Text('•', style: TextStyle(color: Colors.grey)),
                              SizedBox(width: 8),
                              Text(
                                'Exhale',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withOpacity(0.4),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[700],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.music_note,
                                    color: Colors.white54,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'RECOMMENDED TO CALM NERVES',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Midnight Solitude',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'MoodCast • 432Hz Ambient',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.favorite_border,
                                    color: AppTheme.textMuted,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Column(
                            children: [
                              Container(
                                height: 6,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 0.33,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    '1:24',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    '4:10',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shuffle,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () {},
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_previous,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.skip_next,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.repeat,
                                  color: AppTheme.textMuted,
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddedToPlaylist() {
    UIUtils.showSnackBar(
      context,
      'Added to your favorite playlist!',
      icon: Icons.playlist_add_check,
      actionIcon: Icons.rotate_left,
      onActionPressed: () {
        // Add undo logic here if needed
      },
    );
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimerOption('15 Minutes', 15),
            _buildTimerOption('30 Minutes', 30),
            _buildTimerOption('60 Minutes', 60),
            _buildTimerOption('Custom', 0),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerOption(String label, int minutes) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white70)),
      onTap: () {
        Navigator.pop(context);
        if (minutes == 0) {
          _showCustomTimeInput();
        } else {
          _setTimer(label, minutes);
        }
      },
    );
  }

  void _showCustomTimeInput() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Custom Timer',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter minutes',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primary),
            ),
          ),
          onSubmitted: (value) {
            _processCustomTime(dialogContext, value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _processCustomTime(dialogContext, controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _processCustomTime(BuildContext dialogContext, String value) {
    if (value.isNotEmpty) {
      final mins = int.tryParse(value);
      if (mins != null && mins > 0) {
        Navigator.pop(dialogContext);
        _setTimer('$mins Minutes', mins);
      }
    }
  }

  void _setTimer(String label, int minutes) {
    UIUtils.showSnackBar(
      context,
      'Sleep timer set for $label',
      icon: Icons.timer_outlined,
    );
  }

  void _handleShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            // Track Share Card
            Container(
              width: MediaQuery.of(context).size.width * 0.75,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5E66), // Matching the image color
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Track Image
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500&q=80',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Midnight Solitude',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'MoodCast AI • 432Hz Ambient',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'MoodCast AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Interaction Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColorDot(const Color(0xFF8B5E66), isSelected: true),
                const SizedBox(width: 12),
                _buildColorDot(const Color(0xFF4A3439)),
                const SizedBox(width: 12),
                _buildColorDot(const Color(0xFF1A1A1A)),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Social Icons Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildShareAction(
                      'Copy link',
                      Icons.link,
                      Colors.grey[800]!,
                      () => _copyToClipboard(
                        'https://moodcast.ai/track/midnight-solitude',
                      ),
                    ),
                    _buildShareAction(
                      'WhatsApp',
                      FontAwesomeIcons.whatsapp,
                      const Color(0xFF25D366),
                      () => _launchURL(
                        'https://wa.me/?text=Listening to Midnight Solitude on MoodCast AI! https://moodcast.ai/track/midnight-solitude',
                      ),
                    ),
                    _buildShareAction(
                      'Status',
                      FontAwesomeIcons.circleNotch,
                      const Color(0xFF25D366),
                      () => _launchURL(
                        'whatsapp://send?text=Check out this vibe: https://moodcast.ai/track/midnight-solitude',
                      ),
                    ),
                    _buildShareAction(
                      'Messages',
                      Icons.message,
                      const Color(0xFF007AFF),
                      () => _launchURL(
                        'sms:?body=Listen to this with me: https://moodcast.ai/track/midnight-solitude',
                      ),
                    ),
                    _buildShareAction(
                      'Stories',
                      FontAwesomeIcons.facebook,
                      const Color(0xFF1877F2),
                      () => _launchURL(
                        'https://www.facebook.com/sharer/sharer.php?u=https://moodcast.ai/track/midnight-solitude',
                      ),
                    ),
                    _buildShareAction(
                      'TikTok',
                      FontAwesomeIcons.tiktok,
                      Colors.black,
                      () => _launchURL('https://www.tiktok.com/'),
                    ),
                    _buildShareAction(
                      'More',
                      Icons.more_horiz,
                      Colors.grey[700]!,
                      () => _handleGeneralShare(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    UIUtils.showSnackBar(
      context,
      'Link copied to clipboard!',
      icon: Icons.copy_rounded,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        // Try anyway as canLaunchUrl is sometimes unreliable on Android
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      UIUtils.showSnackBar(
        context,
        'Could not open the app. Please make sure it is installed.',
        isError: true,
      );
    }
  }

  Future<void> _handleGeneralShare() async {
    try {
      debugPrint('Opening system share dialog...');
      await Share.share(
        'Check out Midnight Solitude on MoodCast AI! https://moodcast.ai/track/midnight-solitude',
        subject: 'Shared from MoodCast AI',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (!mounted) return;
      UIUtils.showSnackBar(
        context,
        'Could not open system share.',
        isError: true,
      );
    }
  }

  Widget _buildColorDot(Color color, {bool isSelected = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
      ),
    );
  }

  Widget _buildShareAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
