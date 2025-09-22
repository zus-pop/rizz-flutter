import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class VoiceRecordingStep extends StatefulWidget {
  final ProfileSetupData profileData;
  final VoidCallback onNext;

  const VoiceRecordingStep({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<VoiceRecordingStep> createState() => _VoiceRecordingStepState();
}

class _VoiceRecordingStepState extends State<VoiceRecordingStep> {
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  Duration _recordingDuration = Duration.zero;

  final List<String> prompts = [
    "Tell us about your ideal study partner",
    "What makes you laugh the most?",
    "Describe your perfect weekend",
    "What are you passionate about?",
    "Share something interesting about yourself",
  ];

  int _currentPromptIndex = 0;

  @override
  void initState() {
    super.initState();
    // Check if there's already a recording
    _hasRecording = widget.profileData.voiceRecording != null;
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start the timer
      _startTimer();

      // Note: In a real implementation, you would use a package like
      // record or flutter_sound to handle audio recording
      // For now, we'll simulate the recording
    } catch (e) {
      debugPrint('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration = Duration(
            seconds: _recordingDuration.inSeconds + 1,
          );
        });
        _startTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isRecording = false;
      });

      // Simulate creating a recording file
      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/voice_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final file = File(filePath);

      // In a real implementation, this would be the actual recorded audio file
      await file.writeAsString('simulated_audio_data');

      widget.profileData.voiceRecording = file;

      setState(() {
        _hasRecording = true;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _playRecording() {
    setState(() {
      _isPlaying = true;
    });

    // Simulate playback
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingDuration = Duration.zero;
    });
    widget.profileData.voiceRecording = null;
  }

  void _nextPrompt() {
    setState(() {
      _currentPromptIndex = (_currentPromptIndex + 1) % prompts.length;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.onPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section - More prominent
              Text(
                'Add a voice intro',
                style: AppTheme.headline1.copyWith(color: context.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Record a short voice message to help others get to know your personality better',
                style: TextStyle(
                  fontSize: 16,
                  color: context.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Recording Prompt - Smaller and more compact
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: context.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Try talking about:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prompts[_currentPromptIndex],
                      style: AppTheme.body1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _nextPrompt,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: Text(
                        'Try another prompt',
                        style: TextStyle(
                          color: context.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Recording Section - Most prominent
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_hasRecording) ...[
                          // Recording Interface
                          Column(
                            children: [
                              // Simple Recording Button - No animation
                              GestureDetector(
                                onTap: _isRecording
                                    ? _stopRecording
                                    : _startRecording,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: _isRecording
                                        ? Colors.red
                                        : context.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_isRecording
                                                    ? Colors.red
                                                    : context.primary)
                                                .withValues(alpha: 0.3),
                                        blurRadius: 15,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isRecording ? Icons.stop : Icons.mic,
                                    color: context.colors.onPrimary,
                                    size: 50,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Recording Status Text - Prominent
                              Text(
                                _isRecording
                                    ? 'Tap to stop recording'
                                    : 'Tap to start recording',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _isRecording
                                      ? Colors.red
                                      : context.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              // Recording Duration - Only show when recording
                              if (_isRecording) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _formatDuration(_recordingDuration),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Simple Recording Indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Recording...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ] else ...[
                          // Playback Interface - Cleaner layout
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 60,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Recording complete!',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Duration: ${_formatDuration(_recordingDuration)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: context.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Playback Controls - Simplified
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Play Button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isPlaying
                                          ? null
                                          : _playRecording,
                                      icon: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      ),
                                      label: Text(
                                        _isPlaying ? 'Playing...' : 'Play',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.primary,
                                        foregroundColor:
                                            context.colors.onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Delete Button
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _deleteRecording,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Re-record'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade100,
                                        foregroundColor: Colors.grey.shade700,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Actions - Compact
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasRecording ? widget.onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasRecording
                            ? context.primary
                            : context.outline,
                        foregroundColor: _hasRecording
                            ? context.colors.onPrimary
                            : Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _hasRecording ? 2 : 0,
                      ),
                      child: const Text(
                        'Complete Setup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Skip Option - Smaller and less prominent
                  TextButton(
                    onPressed: widget.onNext,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
