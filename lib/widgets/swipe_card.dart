import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:rizz_mobile/models/user.dart';
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
                    color: context.surface.withValues(alpha: 0.3),
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

class StaticWaveform extends StatelessWidget {
  const StaticWaveform({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final heights = [0.4, 0.7, 1.0, 0.8, 0.5];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 50 * heights[index],
          decoration: BoxDecoration(
            color: context.primary,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: context.surface.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class SwipeCard extends StatefulWidget {
  final User user;

  /// SwipeCard accepts only User objects
  const SwipeCard({super.key, required this.user});

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isCompleted = false;
  bool _isAudioLoaded = false; // Track if audio has been loaded
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
    // Remove automatic audio loading - will load on demand when play button is pressed

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
    try {
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

      // Listen for player errors
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isCompleted = true;
          });
        }
      });
    } catch (e) {
      debugPrint('Error setting up audio listeners: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadAudio() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final audioUrl = _getAudioUrl();
      if (audioUrl != null && mounted) {
        await _audioPlayer.setSource(UrlSource(audioUrl));
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isAudioLoaded = true; // Mark as loaded
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // Helper methods to work with User model
  String? _getAudioUrl() {
    return widget.user.audioUrl;
  }

  String _getName() {
    return widget.user.getFullName();
  }

  int _getAge() {
    return widget.user.getAge();
  }

  String? _getBio() {
    return widget.user.bio;
  }

  List<String> _getImageUrls() {
    return widget.user.imageUrls ?? [];
  }

  List<String> _getInterests() {
    return widget.user.interests ?? [];
  }

  String? _getEmotion() {
    return widget.user.emotion;
  }

  String? _getVoiceQuality() {
    return widget.user.voiceQuality;
  }

  String? _getUniversity() {
    return widget.user.university;
  }

  List<String>? _getDealBreakers() {
    return widget.user.dealBreakers;
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset audio state when the user actually changes (different user ID)
    final oldId = oldWidget.user.id;
    final newId = widget.user.id;

    if (oldId != newId) {
      _stopAudioPlayback();
      // Reset audio loaded state for new user - will load on demand
      _isAudioLoaded = false;
      _hasError = false;
      _duration = Duration.zero;
      _position = Duration.zero;
      _isCompleted = false;
    }
    // If it's the same user (e.g., undo), don't touch the audio player
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
    if (!mounted) return;

    if (_isPlaying) {
      _audioPlayer.stop();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _isCompleted = false;
        });
      }
    }
  }

  Future<void> _playPause() async {
    if (!mounted) return;

    // If audio hasn't been loaded yet, load it first
    if (!_isAudioLoaded && !_hasError) {
      await _loadAudio();
    }

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
          if (mounted) {
            setState(() {
              _isCompleted = false;
              _position = Duration.zero;
            });
          }
        } else if (_position > Duration.zero) {
          // Case 3: Resume - audio was paused midway
          await _audioPlayer.resume();
        } else {
          // Case 4: Play - audio stopped at beginning, start fresh
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
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
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: authProvider.isRizzPlus
                  ? [
                      // Premium: Enhanced gradient with gold accents
                      Colors.amber.withValues(alpha: 0.15),
                      context.primary.withValues(alpha: 0.12),
                      Colors.purple.withValues(alpha: 0.15),
                      Colors.blue.withValues(alpha: 0.12),
                      Colors.amber.withValues(alpha: 0.08),
                    ]
                  : [
                      // Non-premium: Standard gradient
                      context.primary.withValues(alpha: 0.15),
                      context.primary.withValues(alpha: 0.08),
                      Colors.purple.withValues(alpha: 0.12),
                      Colors.blue.withValues(alpha: 0.10),
                    ],
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.3,
              ), // Non-premium: white border
              width: authProvider.isRizzPlus
                  ? 2
                  : 1.5, // Premium: thicker border
            ),
            boxShadow: authProvider.isRizzPlus
                ? [
                    // Premium: Enhanced shadows with gold glow
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2),
                      spreadRadius: 2,
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: context.primary.withValues(alpha: 0.15),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    // Non-premium: Standard shadows
                    BoxShadow(
                      color: context.primary.withValues(alpha: 0.2),
                      spreadRadius: 0,
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.15),
                      spreadRadius: 0,
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: context.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Cute profile header with heart decorations
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left side: Avatar and Name
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_getImageUrls().isNotEmpty) ...[
                                        Container(
                                          width: 40,
                                          height: 40,
                                          margin: const EdgeInsets.only(
                                            right: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: context.primary.withValues(
                                                alpha: 0.5,
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: authProvider.isRizzPlus
                                                ? CachedNetworkImage(
                                                    imageUrl:
                                                        _getImageUrls().first,
                                                    fit: BoxFit.cover,
                                                    placeholder: (context, url) =>
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            Container(
                                                              color: context
                                                                  .surface
                                                                  .withValues(
                                                                    alpha: 0.5,
                                                                  ),
                                                              child: Icon(
                                                                Icons.person,
                                                                color: context
                                                                    .onSurface
                                                                    .withValues(
                                                                      alpha:
                                                                          0.6,
                                                                    ),
                                                              ),
                                                            ),
                                                  )
                                                : ImageFiltered(
                                                    imageFilter:
                                                        ImageFilter.blur(
                                                          sigmaX: 8,
                                                          sigmaY: 8,
                                                        ),
                                                    child: CachedNetworkImage(
                                                      imageUrl:
                                                          _getImageUrls().first,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) =>
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => Container(
                                                            color: context
                                                                .surface
                                                                .withValues(
                                                                  alpha: 0.5,
                                                                ),
                                                            child: Icon(
                                                              Icons.person,
                                                              color: context
                                                                  .onSurface
                                                                  .withValues(
                                                                    alpha: 0.6,
                                                                  ),
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                      Text(
                                        '${_getName()}${_getAge() != 0 ? ', ${_getAge()}' : ''}',
                                        style: TextStyle(
                                          color: context.primary,
                                          fontSize: 22,
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
                                    ],
                                  ),

                                  // Right side: View detail button
                                  GestureDetector(
                                    onTap: () async {
                                      if (authProvider.isRizzPlus) {
                                        _showProfileDetails(context);
                                        return;
                                      }

                                      final status =
                                          await presentPaywallIfNeeded();
                                      if (status == PaywallResult.purchased) {
                                        authProvider.isRizzPlus = true;
                                      } else if (status ==
                                          PaywallResult.restored) {
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
                                        color: authProvider.isRizzPlus
                                            ? context.primary.withValues(
                                                alpha: 0.9,
                                              ) // Premium: vibrant primary
                                            : context.surface.withValues(
                                                alpha: 0.8,
                                              ), // Non-premium: subtle surface
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: context.primary.withValues(
                                            alpha: 0.2,
                                          ), // Non-premium: subtle border
                                          width: authProvider.isRizzPlus
                                              ? 3
                                              : 2, // Premium: thicker border
                                        ),
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            authProvider.isRizzPlus
                                                ? Icons
                                                      .visibility // Premium: full visibility
                                                : Icons
                                                      .visibility_off, // Non-premium: restricted
                                            color: authProvider.isRizzPlus
                                                ? Colors
                                                      .white // Premium: white icon
                                                : context.primary.withValues(
                                                    alpha: 0.6,
                                                  ), // Non-premium: muted
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 80),

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

                          // Audio waveform in cute container - now interactive
                          GestureDetector(
                            onTap: _playPause,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.surface,
                                border: Border.all(
                                  color: context.primary.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: _isLoading
                                    ? SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: CircularProgressIndicator(
                                          color: context.primary,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : _hasError
                                    ? Icon(
                                        Icons.error,
                                        color: context.primary,
                                        size: 48,
                                      )
                                    : AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (child, animation) {
                                          return ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          );
                                        },
                                        child: _isPlaying
                                            ? AnimatedWaveform()
                                            : StaticWaveform(),
                                      ),
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

                      // Voice quality and emotion badges
                      if (_getVoiceQuality() != null || _getEmotion() != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_getVoiceQuality() != null)
                                _buildBadge(
                                  context,
                                  _getVoiceQuality()!,
                                  Colors.purple,
                                  Icons.mic,
                                ),
                              const SizedBox(width: 8),
                              if (_getEmotion() != null)
                                _buildBadge(
                                  context,
                                  _getEmotion()!,
                                  Colors.orange,
                                  Icons.sentiment_satisfied_alt,
                                ),
                            ],
                          ),
                        ),

                      // Simplified, subtle audio progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Subtle slider with minimal design
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: context.primary.withValues(
                                  alpha: 0.7,
                                ),
                                inactiveTrackColor: context.onSurface
                                    .withValues(alpha: 0.1),
                                thumbColor: context.primary,
                                overlayColor: context.primary.withValues(
                                  alpha: 0.15,
                                ),
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                  disabledThumbRadius: 3,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12,
                                ),
                                activeTickMarkColor: Colors.transparent,
                                inactiveTickMarkColor: Colors.transparent,
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
                                  if (mounted) {
                                    setState(() {
                                      _isCompleted = false;
                                    });
                                  }
                                },
                              ),
                            ),

                            const SizedBox(height: 2),

                            // Simplified time indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: TextStyle(
                                    color: context.primary.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: TextStyle(
                                    color: context.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // No longer needed as User model has getAge method

  Widget _buildBadge(
    BuildContext context,
    String text,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: .7), color.withValues(alpha: .4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: context.primary,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: context.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26.0, top: 4.0),
            child: Text(
              content,
              style: TextStyle(color: context.onSurface, fontSize: 14),
            ),
          ),
        ],
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
                        if (_getImageUrls().isNotEmpty)
                          Container(
                            height: 250,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: PageView.builder(
                              itemCount: _getImageUrls().length,
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
                                      imageUrl: _getImageUrls()[index],
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
                                '${_getName()}, ${_getAge()}',
                                style: AppTheme.headline1.copyWith(
                                  color: context.onSurface,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Icon(
                                    Icons.school,
                                    size: 20,
                                    color: context.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getUniversity() ??
                                        "Chưa cập nhật trường học",
                                    style: AppTheme.body1.copyWith(
                                      color: context.onSurface,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Gender and interested in
                              Row(
                                children: [
                                  if (widget.user.gender != null) ...[
                                    Icon(
                                      Icons.person,
                                      size: 20,
                                      color: context.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.user.gender!,
                                      style: AppTheme.body1.copyWith(
                                        color: context.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  if (widget.user.interestedIn != null) ...[
                                    Icon(
                                      Icons.favorite_border,
                                      size: 20,
                                      color: Colors.pink,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Quan tâm đến: ${widget.user.interestedIn}',
                                      style: AppTheme.body1.copyWith(
                                        color: context.onSurface,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'Giới thiệu',
                                style: AppTheme.headline4.copyWith(
                                  color: context.primary,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                _getBio() ?? "Chưa có giới thiệu",
                                style: AppTheme.body1.copyWith(
                                  color: context.onSurface,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Voice analysis section
                              if (_getVoiceQuality() != null ||
                                  _getEmotion() != null) ...[
                                Text(
                                  'Phân tích giọng nói',
                                  style: AppTheme.headline4.copyWith(
                                    color: context.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_getVoiceQuality() != null)
                                  _buildDetailItem(
                                    context,
                                    'Chất giọng',
                                    _getVoiceQuality()!,
                                  ),
                                if (_getEmotion() != null)
                                  _buildDetailItem(
                                    context,
                                    'Cảm xúc',
                                    _getEmotion()!,
                                  ),
                                const SizedBox(height: 20),
                              ],

                              Text(
                                'Sở thích',
                                style: AppTheme.headline4.copyWith(
                                  color: context.primary,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: _getInterests().map((interest) {
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

                              const SizedBox(height: 20),

                              // Additional user details
                              Text(
                                'Thêm về tôi',
                                style: AppTheme.headline4.copyWith(
                                  color: context.primary,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Study style
                              if (widget.user.studyStyle != null)
                                _buildDetailItem(
                                  context,
                                  'Phong cách học tập',
                                  widget.user.studyStyle!,
                                ),

                              // Weekend habits
                              if (widget.user.weekendHabit != null)
                                _buildDetailItem(
                                  context,
                                  'Thói quen cuối tuần',
                                  widget.user.weekendHabit!,
                                ),

                              // Campus life
                              if (widget.user.campusLife != null)
                                _buildDetailItem(
                                  context,
                                  'Cuộc sống trên trường',
                                  widget.user.campusLife!,
                                ),

                              // After graduation
                              if (widget.user.afterGraduation != null)
                                _buildDetailItem(
                                  context,
                                  'Sau khi tốt nghiệp',
                                  widget.user.afterGraduation!,
                                ),

                              // Communication preference
                              if (widget.user.communicationPreference != null)
                                _buildDetailItem(
                                  context,
                                  'Phong cách giao tiếp',
                                  widget.user.communicationPreference!,
                                ),

                              // Love language
                              if (widget.user.loveLanguage != null)
                                _buildDetailItem(
                                  context,
                                  'Ngôn ngữ tình yêu',
                                  widget.user.loveLanguage!,
                                ),

                              // Zodiac sign
                              if (widget.user.zodiac != null)
                                _buildDetailItem(
                                  context,
                                  'Cung hoàng đạo',
                                  widget.user.zodiac!,
                                ),

                              // Looking for
                              if (widget.user.lookingFor != null)
                                _buildDetailItem(
                                  context,
                                  'Đang tìm kiếm',
                                  widget.user.lookingFor!,
                                ),

                              // Accent
                              if (widget.user.accent != null)
                                _buildDetailItem(
                                  context,
                                  'Giọng địa phương',
                                  widget.user.accent!,
                                ),

                              // Distance (if available)
                              if (widget.user.distanceKm != null)
                                _buildDetailItem(
                                  context,
                                  'Khoảng cách',
                                  '${widget.user.distanceKm!.toStringAsFixed(1)} km',
                                ),

                              const SizedBox(height: 20),

                              // Deal breakers
                              if ((_getDealBreakers() ?? []).isNotEmpty) ...[
                                Text(
                                  'Deal breakers',
                                  style: AppTheme.headline4.copyWith(
                                    color: Colors.redAccent,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: (_getDealBreakers() ?? []).map((
                                    dealBreaker,
                                  ) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: Colors.redAccent.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        dealBreaker,
                                        style: AppTheme.body2.copyWith(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],

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
