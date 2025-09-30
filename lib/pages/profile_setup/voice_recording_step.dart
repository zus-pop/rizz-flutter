import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
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
  bool _isAnalyzingAudio = false;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final GenerativeModel _model;
  Map<String, dynamic>? _audioAnalysis;

  // Max recording duration in seconds - easily changeable
  static const int _maxRecordingDurationSeconds = 8;
  final List<String> prompts = [
    "Giới thiệu ngắn gọn về bản thân bạn",
    "Bạn thích làm gì vào cuối tuần?",
    "Điều gì khiến bạn cảm thấy hạnh phúc nhất?",
    "Bạn đang tìm kiếm điều gì ở một người bạn đồng hành?",
    "Chia sẻ một sở thích hoặc thói quen đặc biệt của bạn",
  ];
  int _currentPromptIndex = 0;
  void _initializeAI() {
    final jsonSchema = Schema.object(
      properties: {
        'emotion': Schema.enumString(
          enumValues: [
            "Vui",
            "Buồn",
            "Tự tin",
            "Lo lắng",
            "Trung lập",
            // "Bố láo",
            "Ngông",
            "Xấu hổ",
            "Rụt rè",
          ],
          description: 'Cảm xúc của giọng nói',
        ),
        'voice_quality': Schema.enumString(
          enumValues: [
            "Ấm",
            "Khàn",
            "Trong trẻo",
            "Sáng",
            "Mượt",
            "Trầm",
            "Ngang mũi",
            "Thì thào",
          ],
          description: 'Chất lượng của giọng nói',
        ),
        'accent': Schema.enumString(
          enumValues: [
            "Tây Bắc Bộ",
            "Đông Bắc bộ",
            "Đồng bằng sông Hồng",
            "Bắc Trung Bộ",
            "Nam Trung Bộ",
            "Tây Nguyên",
            "Đông Nam Bộ",
            "Miền Tây",
          ],
          description: 'Nguồn gốc của chất giọng trong audio',
        ),
        'overview': Schema.string(
          description:
              '1 câu đánh giá siêu ngắn gọn có thể pha thêm một chút vui nhộn của AI đối với audio, nói rõ giọng này là đến từ tỉnh nào nằm ở trong 8 tiểu vùng miền một chính xác nhất có thể',
        ),
      },
    );
    _model = FirebaseAI.vertexAI(location: 'global').generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: jsonSchema,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeAI();
    // Check if there's already a recording
    _hasRecording = widget.profileData.voiceRecording != null;
    _audioPlayer.onPlayerStateChanged.listen((state) {
      debugPrint('Audio player state changed: $state');
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _isPlaying = false;
            _playbackPosition = Duration.zero;
            debugPrint('Audio completed - setting _isCompleted to true');
          }
        });
      }
    });

    // Listen to position changes for progress tracking
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _playbackPosition = position;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      10,
      (index) => chars[random.nextInt(chars.length)],
      growable: false,
    ).join();
  }

  Future<void> _record() async {
    if (!_isRecording) {
      final status = await Permission.microphone.request();

      if (status == PermissionStatus.granted) {
        await _startRecording();
      } else if (status == PermissionStatus.permanentlyDenied) {
        debugPrint('Permission permanently denied!');
      }
    } else {
      await _stopRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      String filePath = await getApplicationDocumentsDirectory().then(
        (value) => '${value.path}/${_generateRandomId()}',
      );

      // Start the timer
      _startTimer();
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: filePath,
      );
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

        // Auto-stop recording after max duration
        if (_recordingDuration.inSeconds >= _maxRecordingDurationSeconds) {
          _stopRecording();
          return;
        }

        _startTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isRecording = false;
        _isAnalyzingAudio = true;
      });
      String? path = await _audioRecorder.stop();

      // Simulate creating a recording file
      if (path == null) throw UnimplementedError('Path error for the record');

      final file = File(path);
      final prompt = TextPart("Hãy phân tích giọng vùng miền trong audio này.");
      final audio = await file.readAsBytes();
      final audioPart = InlineDataPart('audio/mpeg', audio);
      final response = await _model.generateContent([
        Content.multi([prompt, audioPart]),
      ]);
      debugPrint(response.text);

      // Parse the JSON response
      try {
        if (response.text != null) {
          final jsonResponse = jsonDecode(response.text!);
          setState(() {
            _audioAnalysis = jsonResponse;
          });
          widget.profileData.voiceRecording = file;
          widget.profileData.emotion = jsonResponse['emotion'];
          widget.profileData.voiceQuality = jsonResponse['voice_quality'];
          widget.profileData.accent = jsonResponse['accent'];
        } else {
          throw Exception('Empty response from AI');
        }
      } catch (e) {
        debugPrint('Error parsing AI response: $e');
        setState(() {
          _audioAnalysis = {
            'emotion': 'N/A',
            'voice_quality': 'N/A',
            'overview': 'Không thể phân tích audio',
          };
        });
      }

      setState(() {
        _hasRecording = true;
        _isAnalyzingAudio = false;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() {
        _isAnalyzingAudio = false;
      });
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

  Future<void> _playRecording() async {
    File? file = widget.profileData.voiceRecording;
    if (file != null) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(file.path));
      }
    }
  }

  void _deleteRecording() {
    setState(() {
      _hasRecording = false;
      _recordingDuration = Duration.zero;
      _playbackPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
    widget.profileData.voiceRecording = null;
    widget.profileData.emotion = null;
    widget.profileData.voiceQuality = null;
    widget.profileData.accent = null;
    _audioPlayer.stop();
    _audioRecorder.cancel();
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

  Widget _buildAnalysisRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: context.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section - More prominent
                  Text(
                    'Thêm giọng nói của bạn',
                    style: AppTheme.headline1.copyWith(
                      color: context.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ghi âm một đoạn giới thiệu ngắn để mọi người hiểu rõ hơn về cá tính của bạn.\n\nThời lượng tối đa: ${_maxRecordingDurationSeconds}s giây.',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recording Prompt - Only show when not playing and no recording exists
                  if (!_isPlaying && !_hasRecording) ...[
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
                                'Hãy thử nói:',
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
                              'Thử một gợi ý khác',
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
                    const SizedBox(height: 24),
                  ],

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
                                    onTap: _record,
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
                                        ? 'Recording... (${_maxRecordingDurationSeconds - _recordingDuration.inSeconds}s remaining)'
                                        : 'Tap to start recording (${_maxRecordingDurationSeconds}s max)',
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
                                    // Progress indicator for max duration limit
                                    SizedBox(
                                      width: 200,
                                      child: LinearProgressIndicator(
                                        value:
                                            _recordingDuration.inSeconds /
                                            _maxRecordingDurationSeconds,
                                        backgroundColor: Colors.grey.withValues(
                                          alpha: 0.3,
                                        ),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              Colors.red,
                                            ),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                  // Show AI Analysis when available
                                  if (_audioAnalysis != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.purple.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.smart_toy,
                                                color: Colors.purple,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                'Phân tích giọng nói qua AI',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.purple,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          _buildAnalysisRow(
                                            'Cảm xúc:',
                                            _audioAnalysis!['emotion'] ?? 'N/A',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildAnalysisRow(
                                            'Chất giọng:',
                                            _audioAnalysis!['voice_quality'] ??
                                                'N/A',
                                          ),
                                          const SizedBox(height: 8),
                                          _buildAnalysisRow(
                                            'Vùng miền:',
                                            _audioAnalysis!['accent'] ?? 'N/A',
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withValues(
                                                alpha: 0.05,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.lightbulb,
                                                  color: Colors.purple,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _audioAnalysis!['overview'] ??
                                                        'Không có đánh giá',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: Colors.purple,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],

                                  // Playback Progress with Recording Duration
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.colors.surfaceContainerHigh
                                          .withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        // Recording Duration Header
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Recording Duration: ${_formatDuration(_recordingDuration)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Progress Bar
                                        SliderTheme(
                                          data: SliderTheme.of(context).copyWith(
                                            trackHeight: 4,
                                            thumbShape:
                                                const RoundSliderThumbShape(
                                                  enabledThumbRadius: 8,
                                                ),
                                            overlayShape:
                                                const RoundSliderOverlayShape(
                                                  overlayRadius: 16,
                                                ),
                                          ),
                                          child: Slider(
                                            value:
                                                _totalDuration.inMilliseconds >
                                                    0
                                                ? _playbackPosition
                                                          .inMilliseconds /
                                                      _totalDuration
                                                          .inMilliseconds
                                                : 0.0,
                                            onChanged: (value) {
                                              if (_totalDuration
                                                      .inMilliseconds >
                                                  0) {
                                                final newPosition = Duration(
                                                  milliseconds:
                                                      (value *
                                                              _totalDuration
                                                                  .inMilliseconds)
                                                          .toInt(),
                                                );
                                                _audioPlayer.seek(newPosition);
                                              }
                                            },
                                            activeColor: context.primary,
                                            inactiveColor: Colors.grey
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Time Display
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDuration(
                                                _playbackPosition,
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: context.onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                            Text(
                                              _formatDuration(_totalDuration),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: context.onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Playback Controls - Simplified
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Play/Pause Button
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _playRecording,
                                          icon: Icon(
                                            _isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                          ),
                                          label: Text(
                                            _isPlaying ? 'Pause' : 'Play',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: context.primary,
                                            foregroundColor:
                                                context.colors.onPrimary,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                            backgroundColor: context
                                                .colors
                                                .surfaceContainerHigh,
                                            foregroundColor: context.onSurface,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                : context.onSurface.withValues(alpha: 0.5),
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
                    ],
                  ),
                ],
              ),
            ),

            // Loading Overlay when AI is analyzing
            if (_isAnalyzingAudio) ...[
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Icon(
                          Icons.psychology,
                          color: Colors.blue,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'AI đang phân tích giọng nói của bạn...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vui lòng đợi trong giây lát',
                          style: TextStyle(
                            fontSize: 16,
                            color: context.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
