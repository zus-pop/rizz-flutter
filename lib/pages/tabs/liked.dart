import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/models/profile.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static AudioPlayer? _currentPlayer;

  static void play(AudioPlayer player) {
    // Stop the currently playing audio if different from the new one
    if (_currentPlayer != null && _currentPlayer != player) {
      _currentPlayer!.stop();
    }
    _currentPlayer = player;
  }

  static void stop(AudioPlayer player) {
    if (_currentPlayer == player) {
      _currentPlayer = null;
    }
  }
}

class Liked extends StatefulWidget {
  const Liked({super.key});

  @override
  State<Liked> createState() => _LikedState();
}

class _LikedState extends State<Liked>
    with AutomaticKeepAliveClientMixin<Liked> {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and notification count
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Matches',
                    style: AppTheme.headline2.copyWith(
                      color: context.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Consumer<ProfileProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.likedProfiles.length}',
                          style: AppTheme.body1.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Đây là danh sách những người đã thích bạn\nvà các lượt ghép đôi của bạn.',
                  style: AppTheme.body2.copyWith(
                    color: context.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Content with bottom padding to avoid tab bar
            Expanded(
              child: Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  final likedProfiles = provider.likedProfiles;

                  if (likedProfiles.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return _buildMatchesList(context, likedProfiles, provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(
    BuildContext context,
    List<Profile> profiles,
    ProfileProvider provider,
  ) {
    final todayProfiles = profiles.take(4).toList();
    final yesterdayProfiles = profiles.skip(4).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        if (todayProfiles.isNotEmpty) ...[
          _buildDateSection(context, 'Today', todayProfiles, provider),
          const SizedBox(height: 24),
        ],
        if (yesterdayProfiles.isNotEmpty) ...[
          _buildDateSection(context, 'Yesterday', yesterdayProfiles, provider),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    String dateLabel,
    List<Profile> profiles,
    ProfileProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            dateLabel,
            style: AppTheme.body1.copyWith(
              fontWeight: FontWeight.w600,
              color: context.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3 / 5,
            ),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return _buildMatchCard(context, profile, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: context.outline),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: AppTheme.headline4.copyWith(
                color: context.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'People who like you will appear here',
              style: AppTheme.body2.copyWith(
                color: context.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    Profile profile,
    ProfileProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.outline.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.onSurface.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: context.surface,
          child: Column(
            children: [
              // Profile info at top
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        color: context.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.age}',
                      style: TextStyle(
                        color: context.onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Audio player section
              Expanded(child: _LikedAudioPlayer(profile: profile)),

              // Action buttons at bottom
              _buildActionButtons(context, profile, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Profile profile,
    ProfileProvider provider,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Pass button (left half)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await provider.passLikedProfile(profile.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Passed ${profile.name}'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: context.error,
                      ),
                    );
                  }
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: context.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Icon(Icons.close, color: context.error, size: 24),
                ),
              ),
            ),
          ),

          // Like button (right half)
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await provider.likeProfile(profile.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Liked ${profile.name} again!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppTheme.success(context),
                      ),
                    );
                  }
                },
                child: SizedBox(
                  height: 48,
                  child: Icon(Icons.favorite, color: context.primary, size: 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LikedAudioPlayer extends StatefulWidget {
  final Profile profile;

  const _LikedAudioPlayer({required this.profile});

  @override
  State<_LikedAudioPlayer> createState() => _LikedAudioPlayerState();
}

class _LikedAudioPlayerState extends State<_LikedAudioPlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isCompleted = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
    if (widget.profile.audioUrl != null) {
      _loadAudio();
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isCompleted = state == PlayerState.completed;
          if (state == PlayerState.completed) {
            _isPlaying = false;
            AudioManager.stop(_audioPlayer);
          }
        });
      }
    });
  }

  Future<void> _loadAudio() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _audioPlayer.setSource(UrlSource(widget.profile.audioUrl!));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    AudioManager.stop(_audioPlayer);
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_hasError) {
      await _loadAudio();
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        AudioManager.stop(_audioPlayer);
      } else {
        if (_isCompleted ||
            (_position >= _duration && _duration > Duration.zero)) {
          await _audioPlayer.stop();
          await _audioPlayer.setSource(UrlSource(widget.profile.audioUrl!));
          await _audioPlayer.resume();
          AudioManager.play(_audioPlayer);
          setState(() {
            _isCompleted = false;
            _position = Duration.zero;
          });
        } else {
          await _audioPlayer.resume();
          AudioManager.play(_audioPlayer);
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio waveform visualization
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.graphic_eq, color: context.primary, size: 48),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Play/Pause button
          GestureDetector(
            onTap: _playPause,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withValues(alpha: 0.4),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: context.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : _hasError
                  ? Icon(Icons.error, color: context.onPrimary, size: 24)
                  : Icon(
                      _isPlaying
                          ? Icons.pause
                          : _isCompleted
                          ? Icons.replay
                          : Icons.play_arrow,
                      color: context.onPrimary,
                      size: 28,
                    ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
