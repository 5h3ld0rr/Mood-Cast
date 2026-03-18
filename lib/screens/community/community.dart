import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../theme.dart';
import '../../services/mood_service.dart';
import '../../services/community_service.dart';
import '../../services/youtube_music_service.dart';
import '../../services/player_service.dart';
import '../../models/community_models.dart';
import '../../models/tribe_models.dart';
import '../../services/notification_service.dart';
import '../../services/tribe_service.dart';
import '../../utils/ui_utils.dart';
import 'tribe_session_screen.dart';

// MoodboardSong class is now in community_models.dart

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _globeController; // slow continuous globe rotation
  final MoodService _moodService = MoodService();
  final CommunityService _communityService = CommunityService();
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  final PlayerService _playerService = PlayerService();
  final ValueNotifier<Color?> _screenGlowColor = ValueNotifier<Color?>(null);

  StreamSubscription? _supportListener;
  int _lastResponseCount = 0;
  bool _isFirstLoad = true;

  final Map<String, Tribe> _moodToTribe = {
    'Happy': Tribe(
      id: 'happy_tribe',
      name: 'Joy Jumpers',
      description:
          'Chasing the light with high-energy rhythms and collective euphoria.',
      colorValue: const Color(0xFFA855F7).toARGB32(),
      icon: Icons.wb_sunny_rounded,
      members: '3.4k',
    ),
    'Sad': Tribe(
      id: 'sad_tribe',
      name: 'Rainy Echoes',
      description:
          'Finding beauty in the blues and melancholic beats for deep reflection.',
      colorValue: Colors.blue.toARGB32(),
      icon: Icons.cloudy_snowing,
      members: '2.8k',
    ),
    'Angry': Tribe(
      id: 'angry_tribe',
      name: 'Storm Riders',
      description:
          'Channelling raw energy through heavy frequencies and intense vibes.',
      colorValue: Colors.red.toARGB32(),
      icon: Icons.bolt_rounded,
      members: '1.2k',
    ),
    'Natural': Tribe(
      id: 'natural_tribe',
      name: 'Aura Circle',
      description:
          'Balanced frequencies and peaceful rhythms for a grounded soul.',
      colorValue: const Color(0xFF10B981).toARGB32(),
      icon: Icons.energy_savings_leaf_rounded,
      members: '4.5k',
    ),
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
                                vsync: this,
                                duration: const Duration(seconds: 4),
                              )..repeat(reverse: true);

    _globeController = AnimationController(
                                vsync: this,
                                duration: const Duration(seconds: 25), // one full rotation
                              )..repeat();

    // Listen for vibes dropped for user's own active request
    _supportListener = _communityService.getActiveSupportRequest().listen((
      post,
    ) {
      if (post != null) {
        final newResponses = post.supportResponses.length;

        // Check if a new vibe was dropped
        if (!_isFirstLoad && newResponses > _lastResponseCount) {
          final latestResponse = post.supportResponses.last;
          debugPrint('DEBUG: New vibe detected from ${latestResponse.userName}');
          
          // Notify ONLY if someone else dropped the vibe
          if (latestResponse.userId != _communityService.uid) {
            debugPrint('DEBUG: Triggering system notification for vibe');
            NotificationService().showSimpleNotification(
              title: 'New Vibe Received! 💖',
              body:
                  '${latestResponse.userName} just dropped a vibe for your lift.',
            );
          } else {
            debugPrint('DEBUG: Vibe was dropped by current user, skipping notification');
          }
        }

        _lastResponseCount = newResponses;
        _isFirstLoad = false;
      } else {
        _lastResponseCount = 0;
        _isFirstLoad = false;
      }
    });

    _moodService.currentMood.addListener(_handleMoodChange);
  }

  void _handleMoodChange() async {
    final mood = _moodService.currentMood.value;
    final isSadOrAngry = mood == 'Sad' || mood == 'Angry';

    // If mood is no longer Sad/Angry, remove active support request
    if (!isSadOrAngry) {
      final activePost = await _communityService.getActiveSupportRequest().first;
      if (activePost != null) {
        await _communityService.deletePost(activePost.id);
        _showFeedback(
          'Mood improved! Support request removed.',
          icon: Icons.auto_awesome_rounded,
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _globeController.dispose();
    _supportListener?.cancel();
    _moodService.currentMood.removeListener(_handleMoodChange);
    super.dispose();
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  void _enterTribeSession(Tribe tribe) {
    if (TribeService().currentTribeId != null &&
        TribeService().currentTribeId != tribe.id) {
      _showFeedback(
        'You must leave your current tribe to join a new one!',
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TribeSessionScreen(
          tribeId: tribe.id,
          tribeName: tribe.name,
          tribeColor: tribe.color,
        ),
      ),
    );
  }

  void _leaveTribeSession() {
    TribeService().leaveTribeSession();
    _showFeedback(
      'You left the tribe session.',
      icon: Icons.logout,
    );
  }

  void _dropAVibe(CommunityPost post) {
    if (post.userId == _communityService.uid) {
      _showFeedback(
        'You cannot drop a vibe for your own post! ✨',
        icon: Icons.info_outline,
      );
      return;
    }

    final currentMood = _moodService.currentMood.value;
    if (currentMood != 'Happy' && currentMood != 'Natural') {
      _showFeedback('Switch to a Happy mood to Drop a Vibe! ✨');
      return;
    }

    // Check how many vibes this user has already dropped for this post
    final userVibeCount = post.supportResponses
        .where((r) => r.userId == _communityService.uid)
        .length;

    if (userVibeCount >= 3) {
      _showFeedback(
        'You have already dropped 3 vibes for this post! 💖',
        icon: Icons.info_outline,
      );
      return;
    }

    _showDropAVibeDialog(post.id);
  }

  void _showDropAVibeDialog(String postId) {
    final searchController = TextEditingController();
    List<YouTubeMusicMetadata> searchResults = [];
    bool isLoading = false;
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: StatefulBuilder(
          builder: (context, setState) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Drop a Healing Vibe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Search for a song that can help shift their mood',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.pinkAccent,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (query) {
                    if (debounce?.isActive ?? false) debounce!.cancel();
                    debounce = Timer(
                      const Duration(milliseconds: 500),
                      () async {
                        if (query.length > 2) {
                          setState(() => isLoading = true);
                          final results = await _ytmService.searchTracks(query);
                          setState(() {
                            searchResults = results;
                            isLoading = false;
                          });
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : searchResults.isEmpty
                      ? Center(
                          child: Text(
                            searchController.text.length > 2
                                ? 'No songs found'
                                : 'Start typing to find a song...',
                            style: const TextStyle(color: Colors.white24),
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final song = searchResults[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: song.artworkUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          song.artworkUrl!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.music_note,
                                        color: Colors.white24,
                                      ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                song.artist,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.send_rounded,
                                color: Colors.pinkAccent,
                              ),
                              onTap: () {
                                _communityService.addSupportResponse(
                                  postId: postId,
                                  songTitle: song.title,
                                  artist: song.artist,
                                  videoId: song.videoId,
                                  coverUrl: song.artworkUrl,
                                  moodColorValue: Colors.amber.toARGB32(),
                                );
                                Navigator.pop(context);
                                _showFeedback(
                                  'Vibe Dropped! +50 Points 💖',
                                  icon: Icons.volunteer_activism,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _postNeedALift() {
    final mood = _moodService.currentMood.value;
    if (mood != 'Sad' && mood != 'Angry') {
      _showFeedback('You can only "Need a Lift" when feeling Sad or Angry! 🧘');
      return;
    }

    final messageController = TextEditingController();
    final themeColor = mood == 'Sad' ? Colors.blue : Colors.red;

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need a Lift',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Share how you\'re feeling... the community is here to drop a healing vibe for you.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: messageController,
                  autofocus: true,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'What\'s on your mind?',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final content = messageController.text.trim();
                          if (content.isNotEmpty) {
                            _communityService.createPost(
                              content: content,
                              userMood: mood,
                              moodColorValue: themeColor.toARGB32(),
                              isSupportRequest: true,
                              overrideUserName: 'Anonymous',
                            );
                            Navigator.pop(context);
                            _showFeedback(
                              'Your support request is now live! 🫂',
                              icon: Icons.favorite,
                            );
                          }
                        },
                        style:
                            ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ).copyWith(
                              shadowColor: WidgetStateProperty.all(
                                themeColor.withValues(alpha: 0.3),
                              ),
                            ),
                        child: const Text(
                          'POST',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _reactToPost(String postId, String reaction) {
    _communityService.reactToPost(postId, reaction);

    final Map<String, Color> reactionColors = {
      'Relatable': Colors.blueAccent,
      'Vibing': Colors.amber,
      'Healing': Colors.greenAccent,
      'Powerful': Colors.redAccent,
    };

    final color = reactionColors[reaction] ?? Colors.white;

    // Trigger Haptic Pulse
    HapticFeedback.mediumImpact();

    // Trigger Screen Animation
    _screenGlowColor.value = color;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _screenGlowColor.value = null;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You felt $reaction! ✨'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 500),
        backgroundColor: color.withValues(alpha: 0.8),
      ),
    );
  }

  void _vibeWithSong(String mood, String songId) {
    _communityService.vibeWithSong(mood, songId);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Vibing! You boosted this track. 🔥'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 800),
        backgroundColor: AppTheme.moodColors[mood] ?? Colors.pinkAccent,
      ),
    );
  }

  void _showAddSongDialog(String mood) {
    final titleController = TextEditingController();
    final artistController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add to the $mood Vibe',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Song Title',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: artistController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Artist',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  artistController.text.isNotEmpty) {
                _communityService.addSongToMoodboard(
                  mood: mood,
                  title: titleController.text,
                  artist: artistController.text,
                );
                Navigator.pop(context);
                _showFeedback('Song added to the Live Moodboard! 🎵');
              }
            },
            child: const Text('ADD VIBE'),
          ),
        ],
      ),
    );
  }

  void _showMoodSnippet(String mood, String region) {
    YouTubeMusicMetadata? snippetMetadata;
    bool isFetching = true;
    bool hasError = false;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (isFetching && !hasError) {
            _ytmService
                .getRecommendationsByMood(mood)
                .then((results) async {
                  if (results.isNotEmpty && mounted) {
                    final song = results.first;
                    setDialogState(() {
                      snippetMetadata = song;
                      isFetching = false;
                    });
                    // Start playback
                    await _playerService.play(
                      SongInfo(
                        title: song.title,
                        artist: song.artist,
                        coverUrl: song.artworkUrl,
                        videoId: song.videoId,
                      ),
                    );
                  } else {
                    setDialogState(() {
                      isFetching = false;
                      hasError = true;
                    });
                  }
                })
                .catchError((e) {
                  if (mounted) {
                    setDialogState(() {
                      isFetching = false;
                      hasError = true;
                    });
                  }
                });
          }

          final themeColor = AppTheme.moodColors[mood] ?? Colors.white;

          return Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mood Snippet: $region',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Collective $mood frequency',
                    style: TextStyle(color: themeColor, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  // Animated Frequency Bars
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        10,
                        (i) => TweenAnimationBuilder<double>(
                          duration: Duration(milliseconds: 300 + (i * 100)),
                          tween: Tween(begin: 10, end: isFetching ? 15 : 40),
                          curve: Curves.easeInOut,
                          builder: (context, val, _) => Container(
                            width: 6,
                            height:
                                val *
                                (isFetching
                                    ? 1
                                    : (math.Random().nextDouble() + 0.5)),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(
                                alpha: isFetching ? 0.3 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    isFetching
                        ? 'Tuning into frequency...'
                        : hasError
                        ? 'Failed to catch the vibe ⚠️'
                        : 'Mashup: ${snippetMetadata?.title ?? 'Unknown Vibz'}',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  if (!isFetching && !hasError)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 10),
                      onEnd: () {
                        _playerService.stop();
                        if (Navigator.canPop(context)) Navigator.pop(context);
                      },
                      builder: (context, value, _) => Column(
                        children: [
                          LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(themeColor),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'PLAYING FREQUENCY • ${(value * 10).toInt()}s',
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (hasError)
                    ElevatedButton(
                      onPressed: () {
                        setDialogState(() {
                          isFetching = true;
                          hasError = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor.withValues(alpha: 0.2),
                        foregroundColor: themeColor,
                      ),
                      child: const Text('RETRY'),
                    )
                  else
                    const SizedBox(
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white24),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      _playerService.stop();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showFeedback(String message, {bool isError = false, IconData? icon}) {
    // Show in-app SnackBar using global UI utility
    UIUtils.showSnackBar(
      context,
      message,
      isError: isError,
      icon: icon,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ValueListenableBuilder<Color?>(
            valueListenable: _screenGlowColor,
            builder: (context, color, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: color == null
                      ? null
                      : RadialGradient(
                          center: Alignment.center,
                          radius: 1.5,
                          colors: [
                            color.withValues(alpha: 0.15),
                            color.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                        ),
                ),
              );
            },
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.backgroundDark.withValues(alpha: 0.9),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Community',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                actions: const [],
              ),

              SliverToBoxAdapter(
                child: ValueListenableBuilder<String>(
                  valueListenable: _moodService.currentMood,
                  builder: (context, mood, _) {
                    final tribe =
                        _moodToTribe[mood] ?? _moodToTribe['Natural']!;

                    return ValueListenableBuilder<String?>(
                      valueListenable: TribeService().currentTribeIdNotifier,
                      builder: (context, currentTribeId, _) {
                        final isJoined = currentTribeId == tribe.id;

                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.fastOutSlowIn,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  tribe.color.withValues(alpha: 0.25),
                                  tribe.color.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: tribe.color.withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: tribe.color.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: tribe.color.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        tribe.icon,
                                        color: tribe.color,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isJoined ? 'Welcome To Tribe' : 'Your Mood Tribe',
                                            style: TextStyle(
                                              color: tribe.color,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          Text(
                                            tribe.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isJoined)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.greenAccent,
                                        size: 28,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tribe.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Wrap(
                                      children: List.generate(
                                        3,
                                        (i) => Transform.translate(
                                          offset: Offset(i * -12.0, 0),
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor: tribe.color
                                                .withValues(alpha: 0.2),
                                            child: Icon(
                                              Icons.person,
                                              size: 14,
                                              color: tribe.color,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    StreamBuilder<List<TribeMember>>(
                                      stream: TribeService().getActiveMembersStream(tribe.id),
                                      builder: (context, snapshot) {
                                        final activeCount = snapshot.data?.length ?? 0;
                                        
                                        return Text(
                                          activeCount > 0
                                              ? '$activeCount others vibing right now'
                                              : 'Be the first to vibe!',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              _enterTribeSession(tribe),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isJoined
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : tribe.color,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: isJoined ? 0 : 8,
                                            shadowColor: tribe.color.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            isJoined ? 'RETURN TO SESSION' : 'JOIN TRIBE',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isJoined) ...[
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        height: 56,
                                        width: 56,
                                        child: ElevatedButton(
                                          onPressed: _leaveTribeSession,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                                            foregroundColor: Colors.redAccent,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Icon(Icons.logout),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Global Mood Pulse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlobalMoodPulse(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Collaborative Moodboards Section
              SliverToBoxAdapter(
                child: ValueListenableBuilder<String>(
                  valueListenable: _moodService.currentMood,
                  builder: (context, mood, _) {
                    final boardMood = _moodToTribe.containsKey(mood)
                        ? mood
                        : 'Natural';
                    final themeColor =
                        AppTheme.moodColors[boardMood] ?? Colors.amber;

                    return StreamBuilder<List<MoodboardSong>>(
                      stream: _communityService.getMoodboardSongs(boardMood),
                      builder: (context, snapshot) {
                        final songs = snapshot.data ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Live ${boardMood}board',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Ranked by the community',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _showAddSongDialog(boardMood),
                                    icon: Icon(
                                      Icons.add_box_rounded,
                                      color: themeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: songs.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No songs added yet. Be the first!',
                                        style: TextStyle(color: Colors.white24),
                                      ),
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      itemCount: songs.length,
                                      itemBuilder: (context, index) {
                                        final song = songs[index];
                                        return _buildMoodboardItem(
                                          song,
                                          boardMood,
                                          index,
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              StreamBuilder<CommunityPost?>(
                stream: _communityService.getActiveSupportRequest(),
                builder: (context, snapshot) {
                  final activePost = snapshot.data;

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HEAL Session',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Help others shift their mood',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              ValueListenableBuilder<String>(
                                valueListenable: _moodService.currentMood,
                                builder: (context, mood, _) {
                                  final isSadOrAngry =
                                      mood == 'Sad' || mood == 'Angry';
                                  if (!isSadOrAngry) {
                                    return const SizedBox.shrink();
                                  }

                                  if (activePost != null) {
                                    return TextButton.icon(
                                      onPressed: () async {
                                        await _communityService.deletePost(
                                          activePost.id,
                                        );
                                        _showFeedback(
                                          'Support request removed',
                                          icon: Icons.delete_outline,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('REMOVE REQUEST'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }

                                  return TextButton.icon(
                                    onPressed: _postNeedALift,
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 18,
                                    ),
                                    label: const Text('NEED A LIFT'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blueAccent,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (activePost != null &&
                              activePost.supportResponses.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'VIBES RECEIVED',
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: activePost.supportResponses.length,
                                itemBuilder: (context, index) {
                                  final vibe =
                                      activePost.supportResponses.reversed.toList()[index];
                                  final color = Color(vibe.moodColorValue);

                                  return GestureDetector(
                                    onTap: () {
                                      if (vibe.videoId != null) {
                                        _playerService.play(
                                          SongInfo(
                                            title: vibe.songTitle,
                                            artist: vibe.artist,
                                            coverUrl: vibe.coverUrl,
                                            videoId: vibe.videoId!,
                                          ),
                                        );
                                        _showFeedback(
                                          'Playing vibe from ${vibe.userName} 🎵',
                                          icon: Icons.play_circle_outline,
                                        );
                                      } else {
                                        _showFeedback('Vibing with this track!');
                                      }
                                    },
                                    child: Container(
                                      width: 200,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: color.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: vibe.coverUrl != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      vibe.coverUrl!,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.music_note_rounded,
                                                    color: color,
                                                    size: 20,
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  vibe.songTitle,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                Text(
                                                  vibe.artist,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(
                                                      alpha: 0.5,
                                                    ),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'from ${vibe.userName}',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: color.withValues(
                                                      alpha: 0.8,
                                                    ),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              ValueListenableBuilder<String>(
                valueListenable: _moodService.currentMood,
                builder: (context, mood, _) {
                  final isHappyOrNatural = mood == 'Happy' || mood == 'Natural';
                  if (!isHappyOrNatural) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return StreamBuilder<List<CommunityPost>>(
                    stream: _communityService.getPosts(),
                    builder: (context, snapshot) {
                      final posts = snapshot.data ?? [];
                      if (posts.isEmpty &&
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final post = posts[index];
                          return _buildSupportPost(post, index);
                        }, childCount: posts.length),
                      );
                    },
                  );
                },
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalMoodPulse() {
    return Container(
      height: 340,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.deepPurple.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Container(
                width: 280 + (_pulseController.value * 20),
                height: 280 + (_pulseController.value * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.06 + _pulseController.value * 0.06),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),

          // Globe painter — driven by slow globe controller
          AnimatedBuilder(
            animation: _globeController,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(260, 260),
                painter: _GlobePainter(rotation: _globeController.value * 2 * math.pi),
              );
            },
          ),

          // Nodes pinned to continent centroids — same projection as _GlobePainter
          _buildRegionalNode('US',   'Happy',     38.0, -97.0),  // continental US
          _buildRegionalNode('EU',   'Sad',       51.0,  10.0),  // central Europe
          _buildRegionalNode('ASIA', 'Natural',   40.0,  95.0),  // central Asia
          _buildRegionalNode('LA',   'Angry',    -15.0, -55.0),  // South America
          _buildRegionalNode('AF',   'Natural',    2.0,  20.0),  // Africa
        ],
      ),
    );
  }

  /// Places a mood label exactly on the continent centroid [latDeg, lngDeg],
  /// using the same orthographic projection as [_GlobePainter].
  Widget _buildRegionalNode(
    String label,
    String mood,
    double latDeg,
    double lngDeg,
  ) {
    return AnimatedBuilder(
      animation: _globeController,
      builder: (context, child) {
        const double r = 130.0; // must match CustomPaint size 260×260 → r = 260/2
        final globeRot = _globeController.value * 2 * math.pi;

        // ── Same formula as _GlobePainter ──────────────────────────────────
        final lat = latDeg * math.pi / 180;
        final lng = (lngDeg * math.pi / 180) + globeRot;
        final cosLat = math.cos(lat);

        // Visibility: positive means front hemisphere (same as painter's _project)
        final vis = cosLat * math.cos(lng);
        if (vis < 0.08) return const SizedBox.shrink(); // behind globe

        // Projected screen offset from globe centre
        final x = r * cosLat * math.sin(lng);
        final y = -r * math.sin(lat); // negative because screen y is inverted

        final color = AppTheme.moodColors[mood] ?? Colors.white;
        final opacity = vis.clamp(0.2, 1.0);
        final scale  = 0.72 + vis * 0.28; // perspective scale: smaller at limb

        return Transform.translate(
          offset: Offset(x, y),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: () => _showMoodSnippet(mood, label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.55), width: 0.8),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportPost(CommunityPost post, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: post.moodColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: post.moodColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: post.moodColor.withValues(alpha: 0.2),
                child: Text(
                  post.userName.isNotEmpty ? post.userName[0] : '?',
                  style: TextStyle(
                    color: post.moodColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Feeling ${post.userMood} • ${_getTimeAgo(post.timestamp)}',
                    style: TextStyle(
                      color: post.moodColor.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          if (post.supportResponses.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.volunteer_activism_rounded,
                        color: post.moodColor,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Vibes Shared',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...post.supportResponses.reversed.take(5).map(
                    (res) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Color(res.moodColorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: res.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' sent ',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                      TextSpan(
                                        text: res.songTitle,
                                        style: TextStyle(
                                          color: Color(res.moodColorValue),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'by ${res.artist}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Reaction Bar - only show if NOT a support request
          if (!post.isSupportRequest)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildReactionButton(
                    post.id,
                    post.reactions,
                    'Relatable',
                    '🫂',
                    Colors.blueAccent,
                  ),
                  _buildReactionButton(
                    post.id,
                    post.reactions,
                    'Vibing',
                    '🔥',
                    Colors.amber,
                  ),
                  _buildReactionButton(
                    post.id,
                    post.reactions,
                    'Healing',
                    '🌿',
                    Colors.greenAccent,
                  ),
                  _buildReactionButton(
                    post.id,
                    post.reactions,
                    'Powerful',
                    '⚡',
                    Colors.redAccent,
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: _moodService.currentMood,
            builder: (context, mood, _) {
              final isHappyOrNatural = mood == 'Happy' || mood == 'Natural';
              if (!isHappyOrNatural) return const SizedBox.shrink();

              return SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _dropAVibe(post),
                  icon: const Icon(Icons.volunteer_activism, size: 18),
                  label: const Text(
                    'DROP A VIBE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.pinkAccent,
                    side: const BorderSide(color: Colors.pinkAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButton(
    String postId,
    Map<String, int> reactions,
    String label,
    String emoji,
    Color color,
  ) {
    final count = reactions[label] ?? 0;
    return GestureDetector(
      onTap: () => _reactToPost(postId, label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodboardItem(MoodboardSong song, String mood, int index) {
    final color = AppTheme.moodColors[mood] ?? Colors.amber;

    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.music_note,
                      color: color.withValues(alpha: 0.5),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _vibeWithSong(mood, song.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.flash_on, color: color, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      song.vibes > 999
                          ? '${(song.vibes / 1000).toStringAsFixed(1)}k'
                          : '${song.vibes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 35,
            right: 5,
            child: Text(
              '#${index + 1}',
              style: TextStyle(
                color: color.withValues(alpha: 0.2),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a rotating globe with a lat/lng wire-frame grid using perspective projection.
class _GlobePainter extends CustomPainter {
  final double rotation;
  _GlobePainter({required this.rotation});

  // Projects a [lat°, lng°] point onto screen given globe centre/radius/rotation.
  // Returns null when the point is on the back hemisphere.
  Offset? _project(double latDeg, double lngDeg, double cx, double cy, double r) {
    final lat = latDeg * math.pi / 180;
    final lng = (lngDeg * math.pi / 180) + rotation;
    final cosLat = math.cos(lat);
    final vis = cosLat * math.cos(lng); // positive = front hemisphere
    if (vis < -0.15) return null; // cull back-side
    final x = cx + r * cosLat * math.sin(lng);
    final y = cy - r * math.sin(lat);
    return Offset(x, y);
  }

  // Draws a polygon land mass from [lat,lng] pairs, fading by avg visibility.
  void _drawLandPoly(
    Canvas canvas, double cx, double cy, double r,
    List<List<double>> pts, Color fill, Color stroke,
  ) {
    final path = Path();
    bool started = false;
    double visSum = 0;
    int visCount = 0;

    for (final pt in pts) {
      final proj = _project(pt[0], pt[1], cx, cy, r);
      if (proj == null) {
        // Gap in polygon when crossing limb — restart path segment
        if (started) { path.close(); started = false; }
        continue;
      }
      // Accumulate average visibility for opacity
      final lat = pt[0] * math.pi / 180;
      final lng = (pt[1] * math.pi / 180) + rotation;
      visSum += math.cos(lat) * math.cos(lng);
      visCount++;

      if (!started) { path.moveTo(proj.dx, proj.dy); started = true; }
      else path.lineTo(proj.dx, proj.dy);
    }
    if (started) path.close();

    final avgVis = visCount > 0 ? (visSum / visCount).clamp(0.0, 1.0) : 0.0;
    if (avgVis <= 0) return;

    canvas.drawPath(path, Paint()..color = fill.withValues(alpha: fill.a * avgVis)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = stroke.withValues(alpha: stroke.a * avgVis)..style = PaintingStyle.stroke..strokeWidth = 0.7);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // ── Atmosphere ──────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy), r * 1.06,
      Paint()..shader = RadialGradient(
        colors: [Colors.transparent, Colors.blueAccent.withValues(alpha: 0.12), Colors.transparent],
        stops: const [0.88, 0.96, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.06)),
    );

    // ── Ocean ───────────────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [const Color(0xFF1b3a6b), const Color(0xFF071428)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );

    // ── Clip everything inside sphere ────────────────────────────────────────
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r - 0.5)));

    // ── Grid lines ──────────────────────────────────────────────────────────
    // Latitude
    for (int lat = -60; lat <= 60; lat += 30) {
      final latRad = lat * math.pi / 180;
      final ry = math.cos(latRad) * r;
      final yy = cy - math.sin(latRad) * r;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, yy), width: ry * 2, height: ry * 0.55),
        Paint()..color = Colors.white.withValues(alpha: 0.06)..style = PaintingStyle.stroke..strokeWidth = 0.6,
      );
    }
    // Equator slightly brighter
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 0.55),
      Paint()..color = Colors.white.withValues(alpha: 0.14)..style = PaintingStyle.stroke..strokeWidth = 0.8,
    );
    // Longitude meridians
    for (int lng = 0; lng < 180; lng += 30) {
      final lngRad = (lng * math.pi / 180) + rotation;
      final sinL = math.sin(lngRad);
      final vis = math.cos(lngRad); // front = positive
      final gridAlpha = (vis * 0.10).clamp(0.02, 0.12);
      final path = Path();
      bool first = true;
      for (int lat = -88; lat <= 88; lat += 4) {
        final latRad2 = lat * math.pi / 180;
        final x = cx + r * math.cos(latRad2) * sinL;
        final y = cy - r * math.sin(latRad2);
        if (first) { path.moveTo(x, y); first = false; } else path.lineTo(x, y);
      }
      canvas.drawPath(path, Paint()..color = Colors.lightBlueAccent.withValues(alpha: gridAlpha)..style = PaintingStyle.stroke..strokeWidth = 0.6);
    }

    // ── Continents ──────────────────────────────────────────────────────────
    const landFill   = Color(0xFF2dbd7e);
    const landStroke = Color(0xFF5fffc0);

    // ▸ North America (simplified outline)
    _drawLandPoly(canvas, cx, cy, r, [
      [70,-140],[72,-120],[70,-95],[65,-85],[60,-75],[55,-65],[50,-55],[47,-53],
      [45,-60],[43,-66],[41,-70],[37,-76],[30,-81],[25,-80],[24,-82],[28,-90],
      [29,-94],[26,-97],[22,-97],[20,-87],[15,-83],[12,-83],[8,-77],[8,-77],
      [9,-79],[11,-84],[14,-87],[16,-88],[21,-86],[25,-90],[30,-89],[34,-89],
      [36,-90],[38,-90],[40,-88],[42,-83],[46,-84],[48,-88],[47,-92],[46,-95],
      [47,-99],[47,-104],[47,-110],[46,-117],[48,-122],[54,-130],[58,-134],
      [60,-142],[61,-150],[60,-152],[56,-158],[57,-161],[64,-165],[66,-168],
      [68,-166],[70,-162],[72,-157],[72,-152],[72,-140],[70,-140],
    ], landFill.withValues(alpha: 0.28), landStroke.withValues(alpha: 0.5));

    // ▸ Greenland
    _drawLandPoly(canvas, cx, cy, r, [
      [76,-68],[74,-55],[70,-52],[68,-52],[66,-53],[64,-52],[62,-48],[61,-44],
      [64,-40],[67,-34],[70,-25],[72,-22],[75,-20],[77,-18],[80,-18],[83,-30],
      [83,-38],[82,-45],[80,-52],[79,-60],[76,-68],
    ], landFill.withValues(alpha: 0.22), landStroke.withValues(alpha: 0.4));

    // ▸ South America
    _drawLandPoly(canvas, cx, cy, r, [
      [12,-72],[11,-62],[10,-63],[8,-60],[5,-52],[2,-50],[0,-50],[-3,-41],
      [-5,-35],[-8,-35],[-10,-38],[-12,-40],[-15,-40],[-18,-39],[-22,-42],
      [-23,-43],[-28,-48],[-30,-50],[-33,-53],[-38,-57],[-42,-62],[-46,-65],
      [-50,-69],[-53,-70],[-55,-64],[-55,-66],[-52,-68],[-47,-65],[-44,-65],
      [-40,-62],[-35,-57],[-28,-50],[-22,-43],[-18,-40],[-15,-75],[-10,-76],
      [-5,-80],[0,-78],[5,-77],[10,-75],[12,-72],
    ], landFill.withValues(alpha: 0.28), landStroke.withValues(alpha: 0.5));

    // ▸ Europe (simplified)
    _drawLandPoly(canvas, cx, cy, r, [
      [36,-9],[38,-9],[40,-8],[44,-8],[44,-1],[46,2],[47,7],[47,13],[45,13],
      [44,15],[42,18],[40,18],[38,16],[37,14],[37,15],[38,20],[40,20],[41,22],
      [42,28],[44,28],[45,29],[46,30],[48,30],[48,22],[52,21],[54,18],[54,14],
      [55,12],[57,10],[58,7],[58,5],[56,4],[54,10],[54,14],[54,18],[57,22],
      [60,25],[62,25],[65,25],[68,28],[70,28],[71,26],[70,20],[68,16],[64,14],
      [62,6],[60,5],[58,5],[56,4],[51,2],[50,-2],[48,-5],[45,-2],[44,0],[43,-2],
      [40,-8],[38,-9],[36,-9],
    ], landFill.withValues(alpha: 0.28), landStroke.withValues(alpha: 0.5));

    // ▸ Africa
    _drawLandPoly(canvas, cx, cy, r, [
      [37,10],[34,12],[30,32],[28,34],[22,37],[18,38],[12,42],[10,44],[8,48],
      [12,50],[14,50],[12,44],[12,42],[15,38],[18,38],[22,36],[24,32],[24,18],
      [22,14],[16,12],[12,14],[8,16],[6,2],[4,2],[2,10],[0,10],[-5,10],
      [-5,14],[-8,14],[-10,16],[-12,14],[-15,12],[-17,12],[-18,30],[-20,34],
      [-22,36],[-26,33],[-28,30],[-30,28],[-34,26],[-34,18],[-30,16],
      [-26,14],[-20,12],[-16,6],[-12,2],[-5,-2],[0,-3],[4,8],[8,2],[12,-2],
      [16,-2],[20,2],[24,10],[28,8],[32,2],[36,10],[37,10],
    ], landFill.withValues(alpha: 0.28), landStroke.withValues(alpha: 0.5));

    // ▸ Asia (coarse approximation)
    _drawLandPoly(canvas, cx, cy, r, [
      [70,30],[72,50],[72,70],[70,80],[68,90],[68,100],[66,110],[60,120],
      [55,130],[52,140],[48,140],[44,132],[40,128],[36,126],[34,120],[28,120],
      [22,114],[20,110],[16,100],[10,100],[8,98],[6,100],[4,102],[2,104],
      [0,109],[-2,110],[-6,106],[-4,102],[0,100],[4,96],[8,90],[12,80],
      [18,72],[22,68],[24,60],[24,54],[26,50],[28,48],[32,36],[36,36],[38,28],
      [42,28],[44,40],[44,50],[44,52],[48,50],[52,50],[56,40],[60,30],[64,30],
      [68,30],[70,30],
    ], landFill.withValues(alpha: 0.28), landStroke.withValues(alpha: 0.5));

    // ▸ Australia
    _drawLandPoly(canvas, cx, cy, r, [
      [-14,128],[-16,136],[-14,136],[-12,136],[-12,140],[-14,142],[-18,146],
      [-22,152],[-24,153],[-28,154],[-32,152],[-34,150],[-38,146],[-38,140],
      [-36,136],[-34,116],[-30,114],[-26,114],[-22,114],[-18,122],[-14,128],
    ], landFill.withValues(alpha: 0.28), landStroke.withValues(alpha: 0.5));

    // ▸ Antarctica (just top edge visible at bottom of globe)
    _drawLandPoly(canvas, cx, cy, r, [
      [-70,-180],[-75,-120],[-72,-60],[-74,0],[-72,60],[-75,120],[-70,180],
    ], landFill.withValues(alpha: 0.18), landStroke.withValues(alpha: 0.3));

    canvas.restore();

    // ── Specular / rim ──────────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..shader = RadialGradient(
        center: const Alignment(-0.48, -0.48),
        radius: 0.7,
        colors: [Colors.white.withValues(alpha: 0.14), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
    );
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()..color = Colors.blueAccent.withValues(alpha: 0.28)..style = PaintingStyle.stroke..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_GlobePainter old) => old.rotation != rotation;
}
