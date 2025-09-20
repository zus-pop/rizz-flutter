import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rizz_mobile/models/user_profile.dart';

class SwipeCard extends StatefulWidget {
  final UserProfile profile;

  const SwipeCard({super.key, required this.profile});

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    debugPrint(widget.profile.name);
    // Ensure currentImageIndex is valid for the current profile
    if (widget.profile.imageUrls.isEmpty) {
      currentImageIndex = 0;
    } else {
      currentImageIndex = 0.clamp(0, widget.profile.imageUrls.length - 1);
    }
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset image index when profile changes
    if (widget.profile != oldWidget.profile) {
      debugPrint(
        '${oldWidget.profile.name} was replaced by ${widget.profile.name}',
      );
      if (widget.profile.imageUrls.isEmpty) {
        currentImageIndex = 0;
      } else {
        currentImageIndex = 0.clamp(0, widget.profile.imageUrls.length - 1);
      }
    }
  }

  void _nextImage() {
    if (widget.profile.imageUrls.length > 1) {
      setState(() {
        currentImageIndex =
            (currentImageIndex + 1) % widget.profile.imageUrls.length;
      });
    }
  }

  void _previousImage() {
    if (widget.profile.imageUrls.length > 1) {
      setState(() {
        currentImageIndex = currentImageIndex > 0
            ? currentImageIndex - 1
            : widget.profile.imageUrls.length - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            // Background image
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image:
                    widget.profile.imageUrls.isNotEmpty &&
                        currentImageIndex >= 0 &&
                        currentImageIndex < widget.profile.imageUrls.length
                    ? DecorationImage(
                        image: NetworkImage(
                          widget.profile.imageUrls[currentImageIndex],
                        ),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Handle image loading error
                        },
                      )
                    : null,
                color: widget.profile.imageUrls.isEmpty
                    ? Colors.grey[300]
                    : null,
              ),
              child:
                  widget.profile.imageUrls.isNotEmpty &&
                      currentImageIndex >= 0 &&
                      currentImageIndex < widget.profile.imageUrls.length
                  ? CachedNetworkImage(
                      imageUrl: widget.profile.imageUrls[currentImageIndex],
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),

            // Gradient overlay for better text visibility
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Touch zones for image navigation - positioned on top
            if (widget.profile.imageUrls.length > 1) ...[
              // Left tap zone
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.4,
                child: GestureDetector(
                  onTap: _previousImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Right tap zone
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.4,
                child: GestureDetector(
                  onTap: _nextImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],

            // User information - with pointer events for info button only
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: false,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and age
                      Row(
                        children: [
                          Expanded(
                            child: IgnorePointer(
                              child: Text(
                                '${widget.profile.name}, ${widget.profile.age}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Info button - only this should be tappable
                          GestureDetector(
                            onTap: () => _showProfileDetails(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Location
                      IgnorePointer(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.profile.location,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Bio (truncated)
                      IgnorePointer(
                        child: Text(
                          widget.profile.bio,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Interests chips
                      IgnorePointer(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: widget.profile.interests.take(3).map((
                            interest,
                          ) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFfa5eff).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Photo indicators
            if (widget.profile.imageUrls.length > 1)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: widget.profile.imageUrls.asMap().entries.map((
                    entry,
                  ) {
                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: EdgeInsets.only(
                          right:
                              entry.key == widget.profile.imageUrls.length - 1
                              ? 0
                              : 4,
                        ),
                        decoration: BoxDecoration(
                          color: entry.key == currentImageIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Audio icon - positioned in top right corner
            if (widget.profile.audioUrl != null)
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => _showAudioModal(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAudioModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AudioPlayerDialog(
        audioUrl: widget.profile.audioUrl!,
        userName: widget.profile.name,
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
            decoration: const BoxDecoration(
              color: Color(0xFF080026), // Secondary color background
              borderRadius: BorderRadius.only(
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
                        color: Colors.grey[400],
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
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(
                                              Icons.error,
                                              color: Colors.grey,
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
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: Color(0xFFfa5eff),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.profile.location,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFfa5eff),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                widget.profile.bio,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'Interests',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFfa5eff),
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
                                      color: Color(
                                        0xFFfa5eff,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: Color(
                                          0xFFfa5eff,
                                        ).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      interest,
                                      style: TextStyle(
                                        color: Color(0xFFfa5eff),
                                        fontSize: 14,
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

class AudioPlayerDialog extends StatefulWidget {
  final String audioUrl;
  final String userName;

  const AudioPlayerDialog({
    super.key,
    required this.audioUrl,
    required this.userName,
  });

  @override
  State<AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends State<AudioPlayerDialog> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isCompleted = false;
  bool _isRestarting = false; // Track restart operation
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
    _loadAudio();
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
      debugPrint('Audio player state changed: $state');
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isCompleted = state == PlayerState.completed;
          if (state == PlayerState.completed) {
            _isPlaying = false;
            debugPrint('Audio completed - setting _isCompleted to true');
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
      await _audioPlayer.setSource(UrlSource(widget.audioUrl));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      debugPrint('Error loading audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_hasError) {
      // Try to reload audio if there was an error
      await _loadAudio();
      return;
    }

    try {
      if (_isPlaying) {
        debugPrint('Pausing audio');
        await _audioPlayer.pause();
      } else {
        // If audio has completed or is at the end, restart from beginning
        if (_isCompleted ||
            (_position >= _duration && _duration > Duration.zero)) {
          debugPrint('Audio completed - restarting from beginning');

          setState(() {
            _isRestarting = true;
          });

          debugPrint('Trying stop/reload...');
          // If seek fails, fall back to stop/reload
          try {
            await _audioPlayer.stop();
            await _audioPlayer.setSource(UrlSource(widget.audioUrl));
            await _audioPlayer.resume();

            setState(() {
              _isCompleted = false;
              _position = Duration.zero;
              _isRestarting = false;
            });
          } catch (reloadError) {
            debugPrint('Reload also failed: $reloadError');
            setState(() {
              _hasError = true;
              _isRestarting = false;
            });
          }
        } else {
          debugPrint('Resuming audio from position: $_position');
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      debugPrint('Error playing/pausing audio: $e');
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF080026),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${widget.userName}\'s Voice',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Audio waveform visualization
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.graphic_eq,
                  color: Color(0xFFfa5eff),
                  size: 48,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Progress slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFfa5eff),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                thumbColor: const Color(0xFFfa5eff),
                overlayColor: const Color(0xFFfa5eff).withValues(alpha: 0.2),
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
                  await _audioPlayer.seek(Duration(seconds: value.toInt()));
                  setState(() {
                    _isCompleted = false; // Reset completed state when seeking
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Play/Pause button
            GestureDetector(
              onTap: _playPause,
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFfa5eff),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFfa5eff),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading || _isRestarting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : _hasError
                    ? const Icon(Icons.error, color: Colors.white, size: 32)
                    : Icon(
                        _isPlaying
                            ? Icons.pause
                            : _isCompleted
                            ? Icons.replay
                            : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
