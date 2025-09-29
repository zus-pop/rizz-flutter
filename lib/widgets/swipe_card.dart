import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';

class SwipeCard extends StatefulWidget {
  final Profile profile;

  const SwipeCard({super.key, required this.profile});

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
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
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Stop audio when the profile changes (card is being reused for different profile)
    if (oldWidget.profile.id != widget.profile.id) {
      _stopAudioPlayback();
      // Load audio for the new profile
      if (widget.profile.audioUrl != null) {
        _loadAudio();
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _stopAudioPlayback() {
    if (_isPlaying) {
      _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _isCompleted = false;
      });
    }
  }

  Future<void> _playPause() async {
    if (_hasError) {
      await _loadAudio();
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_isCompleted ||
            (_position >= _duration && _duration > Duration.zero)) {
          await _audioPlayer.stop();
          await _audioPlayer.setSource(UrlSource(widget.profile.audioUrl!));
          await _audioPlayer.resume();
          setState(() {
            _isCompleted = false;
            _position = Duration.zero;
          });
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.outline.withValues(alpha: 1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              color: context.surface,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile name and age in same row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.profile.name}, ${widget.profile.age}',
                        style: TextStyle(
                          color: context.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Audio waveform visualization
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: context.onSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.graphic_eq,
                          color: context.primary,
                          size: 64,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Progress slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: context.primary,
                      inactiveTrackColor: context.onSurface.withValues(
                        alpha: 0.3,
                      ),
                      thumbColor: context.primary,
                      overlayColor: context.primary.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _duration.inSeconds > 0
                          ? _position.inSeconds.toDouble()
                          : 0.0,
                      max: _duration.inSeconds.toDouble() > 0
                          ? _duration.inSeconds.toDouble()
                          : 1.0,
                      onChanged: (value) async {
                        await _audioPlayer.seek(
                          Duration(seconds: value.toInt()),
                        );
                        setState(() {
                          _isCompleted = false;
                        });
                      },
                    ),
                  ),

                  // Time indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: AppTheme.caption.copyWith(
                            color: context.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: AppTheme.caption.copyWith(
                            color: context.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Play/Pause button
                  GestureDetector(
                    onTap: _playPause,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: context.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.primary.withValues(alpha: 0.4),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: context.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : _hasError
                          ? Icon(
                              Icons.error,
                              color: context.onPrimary,
                              size: 32,
                            )
                          : Icon(
                              _isPlaying
                                  ? Icons.pause
                                  : _isCompleted
                                  ? Icons.replay
                                  : Icons.play_arrow,
                              color: context.onPrimary,
                              size: 36,
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Detail icon in top-right corner
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => _showProfileDetails(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: context.outline.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.visibility,
                    color: context.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.80,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        expand: false,
        snapSizes: [.75],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Draggable handle bar area - larger touch target
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // Scrollable content that includes images and text
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Horizontal image gallery
                        if (widget.profile.imageUrls.isNotEmpty)
                          Container(
                            height: 250,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: PageView.builder(
                              itemCount: widget.profile.imageUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.profile.imageUrls[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          CircularProgressIndicator(),
                                      errorWidget: (context, url, error) {
                                        return Container(
                                          color: context.surface.withValues(
                                            alpha: 0.5,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.error,
                                              color: context.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // Profile content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile details
                              Text(
                                '${widget.profile.name}, ${widget.profile.age}',
                                style: AppTheme.headline1.copyWith(
                                  color: context.onSurface,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: context.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.profile.location,
                                    style: AppTheme.body1.copyWith(
                                      color: context.onSurface,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'About',
                                style: AppTheme.headline4.copyWith(
                                  color: context.primary,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                widget.profile.bio,
                                style: AppTheme.body1.copyWith(
                                  color: context.onSurface,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'Interests',
                                style: AppTheme.headline4.copyWith(
                                  color: context.primary,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: widget.profile.interests.map((
                                  interest,
                                ) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: context.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      interest,
                                      style: AppTheme.body2.copyWith(
                                        color: context.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(
                                height: 100,
                              ), // Extra space for bottom sheet
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
