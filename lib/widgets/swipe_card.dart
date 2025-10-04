import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:rizz_mobile/models/profile.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:rizz_mobile/utils/paywall.dart';

class AnimatedWaveform extends StatefulWidget {
  const AnimatedWaveform({super.key});

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<double> _baseHeights;

  @override
  void initState() {
    super.initState();
    _baseHeights = [
      0.4,
      0.7,
      1.0,
      0.8,
      0.5,
    ]; // Different base heights for each bar

    _controllers = List.generate(5, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 300 + index * 150),
        vsync: this,
      )..repeat(reverse: true);
    });

    _animations = List.generate(5, (index) {
      return Tween<double>(
        begin: _baseHeights[index] * 0.3,
        end: _baseHeights[index],
      ).animate(
        CurvedAnimation(parent: _controllers[index], curve: Curves.easeInOut),
      );
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 50 * _animations[index].value,
              decoration: BoxDecoration(
                color: context.primary,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

class SwipeCard extends StatefulWidget {
  final Profile profile;

  const SwipeCard({super.key, required this.profile});

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isCompleted = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Animation controllers for rotating circles
  late AnimationController _outerRingController;
  late AnimationController _middleRingController;
  late AnimationController _outermostRingController;
  late Animation<double> _outerRingAnimation;
  late Animation<double> _middleRingAnimation;
  late Animation<double> _outermostRingAnimation;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
    if (widget.profile.audioUrl != null) {
      _loadAudio();
    }

    // Initialize rotation animation controllers
    _middleRingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _outerRingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _outermostRingController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _middleRingAnimation = Tween<double>(
      begin: 0.0,
      end: -2 * pi, // Negative for counter-clockwise
    ).animate(_middleRingController);

    _outerRingAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_outerRingController);

    _outermostRingAnimation = Tween<double>(
      begin: 0.0,
      end: -2 * pi,
    ).animate(_outermostRingController);
  }

  void _setupAudioListeners() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
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

        // Control rotation animations
        if (state == PlayerState.playing) {
          _outerRingController.repeat();
          _middleRingController.repeat();
          _outermostRingController.repeat();
        } else {
          _outerRingController.stop();
          _middleRingController.stop();
          _outermostRingController.stop();
        }
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
    _outerRingController.dispose();
    _middleRingController.dispose();
    _outermostRingController.dispose();
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
        // Case 1: Currently playing, so pause
        await _audioPlayer.pause();
      } else {
        // Determine the appropriate action based on current state
        if (_isCompleted ||
            (_position >= _duration && _duration > Duration.zero)) {
          // Case 2: Replay - audio completed, restart from beginning
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.resume();
          setState(() {
            _isCompleted = false;
            _position = Duration.zero;
          });
        } else if (_position > Duration.zero) {
          // Case 3: Resume - audio was paused midway
          await _audioPlayer.resume();
        } else {
          // Case 4: Play - audio stopped at beginning, start fresh
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
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.primary.withValues(alpha: 0.1),
                context.primary.withValues(alpha: 0.05),
                Colors.pink.withValues(alpha: 0.08),
                Colors.purple.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: context.primary.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: context.primary.withValues(alpha: 0.15),
                spreadRadius: 1,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.pink.withValues(alpha: 0.1),
                spreadRadius: 0,
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: context.surface,
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cute profile header with heart decorations
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Cute background bubble
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: context.surface,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: context.primary.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Cute heart icon
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.pink,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.profile.name}, ${widget.profile.age}',
                                  style: TextStyle(
                                    color: context.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: context.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        offset: const Offset(0, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Another cute heart
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.pink.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.pink,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Floating sparkles
                          Positioned(
                            top: -2,
                            right: 0,
                            child: Icon(
                              Icons.star,
                              color: Colors.yellow.withValues(alpha: 0.8),
                              size: 18,
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            left: 0,
                            child: Icon(
                              Icons.star,
                              color: Colors.pink.withValues(alpha: 0.6),
                              size: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Cute audio visualization area
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outermost cute ring with rotation
                          AnimatedBuilder(
                            animation: _outermostRingAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _outermostRingAnimation.value,
                                child: Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: List.generate(8, (index) {
                                      final angle = (index * 45) * (pi / 180);
                                      return Positioned(
                                        left: 120 + 100 * cos(angle) - 4,
                                        top: 120 + 100 * sin(angle) - 4,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.pink.withValues(
                                              alpha: 0.3,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Outer cute ring with rotation
                          AnimatedBuilder(
                            animation: _outerRingAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _outerRingAnimation.value,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    children: List.generate(6, (index) {
                                      final angle = (index * 60) * (pi / 180);
                                      return Positioned(
                                        left: 100 + 80 * cos(angle) - 6,
                                        top: 100 + 80 * sin(angle) - 6,
                                        child: Icon(
                                          Icons.star,
                                          color: Colors.yellow.withValues(
                                            alpha: 0.6,
                                          ),
                                          size: 12,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Middle cute ring with counter-rotation
                          AnimatedBuilder(
                            animation: _middleRingAnimation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _middleRingAnimation.value,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    children: List.generate(6, (index) {
                                      final angle = (index * 60) * (pi / 180);
                                      return Positioned(
                                        left: 80 + 60 * cos(angle) - 6,
                                        top: 80 + 60 * sin(angle) - 6,
                                        child: Icon(
                                          Icons.favorite,
                                          color: context.primary.withValues(
                                            alpha: 0.4,
                                          ),
                                          size: 12,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Audio waveform in cute container
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.surface,
                              border: Border.all(
                                color: _isPlaying
                                    ? context.primary.withValues(alpha: 0.6)
                                    : context.primary.withValues(alpha: 0.4),
                                width: _isPlaying ? 3 : 2,
                              ),
                              boxShadow: _isPlaying
                                  ? [
                                      BoxShadow(
                                        color: context.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Center(
                              child: _isPlaying
                                  ? AnimatedWaveform()
                                  : Icon(
                                      Icons.music_note,
                                      color: context.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                      size: 40,
                                    ),
                            ),
                          ),

                          // Floating cute elements when playing
                          if (_isPlaying) ...[
                            Positioned(
                              top: 20,
                              left: 30,
                              child: AnimatedOpacity(
                                opacity: _isPlaying ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.pink.withValues(alpha: 0.6),
                                  size: 16,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 25,
                              right: 35,
                              child: AnimatedOpacity(
                                opacity: _isPlaying ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.yellow.withValues(alpha: 0.7),
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Cute progress bar container (smaller)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.primary.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.primary.withValues(alpha: 0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Cute slider with pink thumb
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: context.primary,
                                inactiveTrackColor: context.onSurface
                                    .withValues(alpha: 0.2),
                                thumbColor: Colors.pink,
                                overlayColor: Colors.pink.withValues(
                                  alpha: 0.3,
                                ),
                                trackHeight: 6,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
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

                            const SizedBox(height: 2),

                            // Cute time indicators (smaller)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        context.primary.withValues(alpha: 0.2),
                                        context.primary.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: context.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 8,
                                        color: context.primary,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formatDuration(_position),
                                        style: TextStyle(
                                          color: context.primary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.onSurface.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _formatDuration(_duration),
                                    style: TextStyle(
                                      color: context.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Super cute play button
                      GestureDetector(
                        onTap: _playPause,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isPlaying
                                  ? [
                                      Colors.pink,
                                      context.primary,
                                      Colors.purple,
                                    ]
                                  : [
                                      context.primary,
                                      Colors.pink.withValues(alpha: 0.8),
                                      context.primary.withValues(alpha: 0.9),
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isPlaying
                                    ? Colors.pink.withValues(alpha: 0.5)
                                    : context.primary.withValues(alpha: 0.4),
                                spreadRadius: _isPlaying ? 3 : 1,
                                blurRadius: _isPlaying ? 30 : 20,
                                offset: Offset(0, _isPlaying ? 8 : 4),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : _hasError
                              ? Icon(Icons.error, color: Colors.white, size: 36)
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    _isPlaying
                                        ? Icons.pause
                                        : _isCompleted
                                        ? Icons.replay
                                        : Icons.play_arrow,
                                    key: ValueKey<String>(
                                      _isPlaying
                                          ? 'pause'
                                          : (_isCompleted ? 'replay' : 'play'),
                                    ),
                                    color: Colors.white,
                                    size: 42,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Cute detail button in top-right
                Positioned(
                  top: 25,
                  right: 16,
                  child: GestureDetector(
                    onTap: () async {
                      if (authProvider.isRizzPlus) {
                        _showProfileDetails(context);
                        return;
                      }

                      final status = await presentPaywallIfNeeded();
                      if (status == PaywallResult.purchased) {
                        authProvider.isRizzPlus = true;
                      } else if (status == PaywallResult.restored) {
                        debugPrint("Restored");
                        return;
                      } else {
                        debugPrint("No purchased occur");
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: context.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.primary.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
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
      },
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
