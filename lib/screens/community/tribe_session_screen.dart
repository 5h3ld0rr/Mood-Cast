import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../models/tribe_models.dart';
import '../../services/tribe_service.dart';
import '../../services/player_service.dart';
import '../../services/youtube_music_service.dart';
import '../../theme.dart';
import 'dart:ui';

class TribeSessionScreen extends StatefulWidget {
  final String tribeId;
  final String tribeName;
  final Color tribeColor;

  const TribeSessionScreen({
    super.key,
    required this.tribeId,
    required this.tribeName,
    required this.tribeColor,
  });

  @override
  State<TribeSessionScreen> createState() => _TribeSessionScreenState();
}

class _TribeSessionScreenState extends State<TribeSessionScreen> {
  final TribeService _tribeService = TribeService();
  final PlayerService _playerService = PlayerService();
  final YouTubeMusicService _ytmService = YouTubeMusicService();

  TribeSession? _session;
  List<TribeMember> _members = [];
  StreamSubscription? _sessionSub;
  StreamSubscription? _membersSub;
  StreamSubscription? _playerSub;

  String? _currentlyPlayingTrackId;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    _playerService.clearQueue();
    await _tribeService.joinTribeSession(widget.tribeId);

    _sessionSub = _tribeService.getSessionStream(widget.tribeId).listen((session) {
      if (!mounted) return;
      setState(() => _session = session);
      if (session != null) _syncPlayback(session);
    });

    _membersSub = _tribeService.getActiveMembersStream(widget.tribeId).listen((members) {
      if (!mounted) return;
      setState(() => _members = members);
    });

    _playerSub = _playerService.processingStateStream.listen((state) {
      // If song naturally ends, the DJ must trigger the next queue item
      if (state == ProcessingState.completed) {
        if (_session?.currentDJUid == _tribeService.uid) {
          _tribeService.playNextInQueue();
        }
      }
    });
  }

  Future<void> _syncPlayback(TribeSession session) async {
    final track = session.currentTrack;
    if (track == null) {
      if (_currentlyPlayingTrackId != null) {
        await _playerService.stop(isTribeSync: true);
        _currentlyPlayingTrackId = null;
      }
      return;
    }

    if (_currentlyPlayingTrackId != track.id) {
      _currentlyPlayingTrackId = track.id;
      final songInfo = SongInfo(
        title: track.title,
        artist: track.artist,
        coverUrl: track.coverUrl,
        videoId: track.videoId,
      );
      
      await _playerService.play(songInfo, isTribeSync: true);
      
      // Calculate how far into the song we are 
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMs = now - session.startTime;
      if (elapsedMs > 0) {
        // small delay to let player initialize
        await Future.delayed(const Duration(milliseconds: 500)); 
        await _playerService.seekToPosition(Duration(milliseconds: elapsedMs), isTribeSync: true);
      }
    }
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _membersSub?.cancel();
    _playerSub?.cancel();
    // Intentionally NOT calling _tribeService.leaveTribeSession() here
    // so music continues playing when navigating to other tabs.
    super.dispose();
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    List<YouTubeMusicMetadata> searchResults = [];
    bool isLoading = false;
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: StatefulBuilder(
          builder: (context, setStateModal) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark.withAlpha(230),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search to Queue',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search songs...',
                    fillColor: Colors.white10,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onChanged: (query) {
                    if (debounce?.isActive ?? false) debounce!.cancel();
                    debounce = Timer(const Duration(milliseconds: 500), () async {
                      if (query.length > 2) {
                        setStateModal(() => isLoading = true);
                        final results = await _ytmService.searchTracks(query);
                        setStateModal(() {
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
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final song = searchResults[index];
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: song.artworkUrl != null
                                    ? Image.network(song.artworkUrl!, width: 48, height: 48, fit: BoxFit.cover)
                                    : Container(width: 48, height: 48, color: Colors.white10, child: const Icon(Icons.music_note, color: Colors.white24)),
                              ),
                              title: Text(song.title, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54)),
                              trailing: Icon(Icons.add_circle, color: widget.tribeColor),
                              onTap: () {
                                _tribeService.queueSong(TribeTrack(
                                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                                  title: song.title,
                                  artist: song.artist,
                                  coverUrl: song.artworkUrl,
                                  videoId: song.videoId,
                                  addedBy: _tribeService.displayName ?? 'DJ',
                                ));
                                Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: widget.tribeColor)),
      );
    }

    final isDJ = _session?.currentDJUid == _tribeService.uid;
    final hasVotedSkip = _session!.skipVotes.contains(_tribeService.uid);
    final skipThreshold = (_members.isNotEmpty ? _members.length : 1) / 2.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
             child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.tribeColor.withAlpha(50), 
                    AppTheme.backgroundDark,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE TRIBE SESSION',
                            style: TextStyle(color: widget.tribeColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                          ),
                          Text(
                            widget.tribeName,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Player Area
                if (_session!.currentTrack == null) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.speaker_notes_off, color: Colors.white24, size: 64),
                          const SizedBox(height: 16),
                          const Text('Silence...', style: TextStyle(color: Colors.white54, fontSize: 18)),
                          if (isDJ) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showSearchDialog,
                              icon: const Icon(Icons.search),
                              label: const Text('Add a Track'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.tribeColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                          if (!isDJ && _session!.currentDJUid == null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _tribeService.takeCrown(widget.tribeId),
                              style: ElevatedButton.styleFrom(backgroundColor: widget.tribeColor, foregroundColor: Colors.white),
                              child: const Text('Take DJ Crown 👑'),
                            )
                          ]
                        ],
                      ),
                    ),
                  )
                ] else ...[
                  // Cover Art
                  Hero(
                    tag: 'tribe_cover',
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: widget.tribeColor.withAlpha(80), blurRadius: 40, offset: const Offset(0, 20)),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(_session!.currentTrack!.coverUrl ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Song Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        Text(
                          _session!.currentTrack!.title,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _session!.currentTrack!.artist,
                          style: const TextStyle(color: Colors.white54, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // DJ Status & Skip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Text('👑 ', style: TextStyle(fontSize: 12)),
                              Text(
                                isDJ ? 'You are the DJ' : '${_session!.currentDJName} is controlling the aux',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        
                        // Skip Vote Button
                        GestureDetector(
                          onTap: hasVotedSkip ? null : () => _tribeService.voteSkip(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: hasVotedSkip ? Colors.white10 : Colors.redAccent.withAlpha(50),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: hasVotedSkip ? Colors.transparent : Colors.redAccent.withAlpha(100)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.skip_next, color: hasVotedSkip ? Colors.white38 : Colors.redAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  hasVotedSkip ? 'Voted' : 'Skip (${_session!.skipVotes.length}/${skipThreshold.ceil()})',
                                  style: TextStyle(
                                    color: hasVotedSkip ? Colors.white38 : Colors.redAccent, 
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold
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
                  
                  // Queue ListView
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Up Next', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                if (isDJ)
                                  IconButton(
                                    icon: Icon(Icons.add_circle, color: widget.tribeColor),
                                    onPressed: _showSearchDialog,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _session!.queue.isEmpty 
                                ? Center(
                                    child: Text(
                                      isDJ ? 'Search to queue the next track' : 'The DJ hasn\'t queued anything yet',
                                      style: const TextStyle(color: Colors.white38),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _session!.queue.length,
                                    itemBuilder: (context, index) {
                                      final qSong = _session!.queue[index];
                                      return ListTile(
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: qSong.coverUrl != null
                                              ? Image.network(qSong.coverUrl!, width: 40, height: 40, fit: BoxFit.cover)
                                              : Container(width: 40, height: 40, color: Colors.white10),
                                        ),
                                        title: Text(qSong.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                        subtitle: Text(qSong.artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                        trailing: isDJ
                                            ? IconButton(
                                                icon: const Icon(Icons.remove_circle_outline, color: Colors.white24),
                                                onPressed: () => _tribeService.removeFromQueue(qSong),
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
