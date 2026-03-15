import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../theme.dart';
import '../../services/mood_service.dart';
import '../../services/community_service.dart';
import '../../services/youtube_music_service.dart';
import '../../services/player_service.dart';
import '../../models/community_models.dart';

// MoodboardSong class is now in community_models.dart

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final MoodService _moodService = MoodService();
  final CommunityService _communityService = CommunityService();
  final YouTubeMusicService _ytmService = YouTubeMusicService();
  final PlayerService _playerService = PlayerService();
  final ValueNotifier<Color?> _screenGlowColor = ValueNotifier<Color?>(null);

  final Map<String, Tribe> _moodToTribe = {
    'Happy': Tribe(
      id: 'happy_tribe',
      name: 'Joy Jumpers',
      description:
          'Chasing the light with high-energy rhythms and collective euphoria.',
      colorValue: Colors.amber.toARGB32(),
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
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
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

  void _toggleJoinTribe(String tribeId, String tribeName) {
    _communityService.toggleJoinTribe(tribeId);
  }

  void _dropAVibe(String postId) {
    final currentMood = _moodService.currentMood.value;
    if (currentMood != 'Happy' && currentMood != 'Natural') {
      _showError('Switch to a Happy mood to Drop a Vibe! ✨');
      return;
    }

    _showDropAVibeDialog(postId);
  }

  void _showDropAVibeDialog(String postId) {
    final searchController = TextEditingController();
    List<YouTubeMusicMetadata> searchResults = [];
    bool isLoading = false;
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
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
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (query) {
                  if (debounce?.isActive ?? false) debounce!.cancel();
                  debounce = Timer(const Duration(milliseconds: 500), () async {
                    if (query.length > 2) {
                      setState(() => isLoading = true);
                      final results = await _ytmService.searchTracks(query);
                      setState(() {
                        searchResults = results;
                        isLoading = false;
                      });
                    }
                  });
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
                                moodColorValue: Colors.amber.toARGB32(),
                              );
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.volunteer_activism,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Vibe Dropped! +50 Empathy Points 💖',
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Colors.pinkAccent.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
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
    );
  }

  void _postNeedALift() {
    final mood = _moodService.currentMood.value;
    if (mood != 'Sad' && mood != 'Angry') {
      _showError('You can only "Need a Lift" when feeling Sad or Angry! 🧘');
      return;
    }

    _communityService.createPost(
      content:
          'Feeling a bit overwhelmed... sharing a song to help would mean a lot. #NeedALift',
      userMood: mood,
      moodColorValue: mood == 'Sad'
          ? Colors.blue.toARGB32()
          : Colors.red.toARGB32(),
      isSupportRequest: true,
    );

    _showError('Your support request is now live! 🫂');
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
                _showError('Song added to the Live Moodboard! 🎵');
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white12,
      ),
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
                actions: [
                  Center(
                    child: StreamBuilder<int>(
                      stream: _communityService.getEmpathyPoints(),
                      builder: (context, snapshot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          margin: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.pinkAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.pinkAccent.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.volunteer_activism,
                                color: Colors.pinkAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${snapshot.data ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: ValueListenableBuilder<String>(
                  valueListenable: _moodService.currentMood,
                  builder: (context, mood, _) {
                    final tribe =
                        _moodToTribe[mood] ?? _moodToTribe['Natural']!;

                    return StreamBuilder<List<String>>(
                      stream: _communityService.getJoinedTribes(),
                      builder: (context, snapshot) {
                        final joinedTribes = snapshot.data ?? [];
                        final isJoined = joinedTribes.contains(tribe.id);

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
                                            isJoined
                                                ? 'Welcome To Tribe'
                                                : 'Your Mood Tribe',
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
                                    Text(
                                      '${tribe.members} others vibing right now',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _toggleJoinTribe(tribe.id, tribe.name),
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
                                      isJoined
                                          ? 'LEAVE TRIBE'
                                          : 'JOIN THE SESSION',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Row(
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
                      TextButton.icon(
                        onPressed: _postNeedALift,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('NEED A LIFT'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              StreamBuilder<List<CommunityPost>>(
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
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(3, (index) {
                  final size =
                      150.0 + (index * 60) + (_pulseController.value * 30);
                  final opacity =
                      (0.1 - (index * 0.03)) * (1.0 - _pulseController.value);
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber.withValues(
                          alpha: opacity.clamp(0, 1),
                        ),
                        width: 1,
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          _buildRegionalNode('US', 'Happy', 110, 0.5),
          _buildRegionalNode('EU', 'Sad', 120, 2.8),
          _buildRegionalNode('ASIA', 'Natural', 100, 4.5),

          GestureDetector(
            onTap: () => _showMoodSnippet('Happy', 'Global'),
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 100 + (_pulseController.value * 10),
                  height: 100 + (_pulseController.value * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.amber.withValues(alpha: 0.9),
                        Colors.orange.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(
                          alpha: 0.3 * _pulseController.value + 0.2,
                        ),
                        blurRadius: 30 * _pulseController.value + 20,
                        spreadRadius: 10 * _pulseController.value,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'GLOBAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
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
      ),
    );
  }

  Widget _buildRegionalNode(
    String label,
    String mood,
    double radius,
    double initialAngle,
  ) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final angle = initialAngle + (_pulseController.value * 0.1);
        final color = AppTheme.moodColors[mood] ?? Colors.white;

        return Transform.translate(
          offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
          child: GestureDetector(
            onTap: () => _showMoodSnippet(mood, label),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
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
            const Text(
              'Vibes Dropped:',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...post.supportResponses
                .take(2)
                .map(
                  (res) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.music_note,
                          color: Colors.blueAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${res.userName} shared ${res.songTitle}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),
          ],

          // Reaction Bar
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
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _dropAVibe(post.id),
              icon: const Icon(Icons.volunteer_activism, size: 18),
              label: const Text(
                'DROP A VIBE',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.pinkAccent,
                side: const BorderSide(color: Colors.pinkAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
