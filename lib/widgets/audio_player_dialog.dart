import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

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
          color: context.colors.surfaceContainerHighest,
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.onSurface,
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
                    child: Icon(
                      Icons.close,
                      color: context.onSurface,
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
                color: context.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.graphic_eq, color: context.primary, size: 48),
              ),
            ),

            const SizedBox(height: 24),

            // Progress slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: context.primary,
                inactiveTrackColor: context.onSurface.withValues(alpha: 0.3),
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
                width: 64,
                height: 64,
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
                child: _isLoading || _isRestarting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: context.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : _hasError
                    ? Icon(Icons.error, color: context.onPrimary, size: 32)
                    : Icon(
                        _isPlaying
                            ? Icons.pause
                            : _isCompleted
                            ? Icons.replay
                            : Icons.play_arrow,
                        color: context.onPrimary,
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
