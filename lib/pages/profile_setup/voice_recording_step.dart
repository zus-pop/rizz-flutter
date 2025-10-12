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
  bool _isCountingDown = false;
  int _countdownSeconds = 3;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final GenerativeModel _model;
  Map<String, dynamic>? _audioAnalysis;

  // Max recording duration in seconds - easily changeable
  static const int _maxRecordingDurationSeconds = 10;
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
    if (_isCountingDown) {
      // Cancel countdown if user taps during countdown
      setState(() {
        _isCountingDown = false;
      });
      return;
    }

    if (!_isRecording && !_isCountingDown) {
      final status = await Permission.microphone.request();

      if (status == PermissionStatus.granted) {
        await _startCountdown();
      } else if (status == PermissionStatus.permanentlyDenied) {
        debugPrint('Permission permanently denied!');
      }
    } else if (_isRecording) {
      await _stopRecording();
    }
  }

  Future<void> _startCountdown() async {
    setState(() {
      _isCountingDown = true;
      _countdownSeconds = 3;
    });

    // Countdown timer
    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isCountingDown) {
        setState(() {
          _countdownSeconds = i - 1;
        });
      } else {
        // Countdown was cancelled
        return;
      }
    }

    // Start recording after countdown
    if (mounted && _isCountingDown) {
      setState(() {
        _isCountingDown = false;
      });
      await _startRecording();
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

  // Build helper methods for cleaner UI components
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi âm giọng nói',
          style: AppTheme.headline1.copyWith(
            color: context.onSurface,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hãy giới thiệu bản thân để AI phân tích và mọi người hiểu thêm về bạn',
          style: TextStyle(
            fontSize: 16,
            color: context.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPromptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primary.withValues(alpha: 0.12),
            context.primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, color: context.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Gợi ý câu hỏi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            prompts[_currentPromptIndex],
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: context.onSurface,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _nextPrompt,
            icon: Icon(Icons.refresh, size: 18, color: context.primary),
            label: Text(
              'Thử câu hỏi khác',
              style: TextStyle(
                color: context.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: _record,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isCountingDown
                    ? [
                        context.colors.tertiaryContainer,
                        context.colors.tertiary.withValues(alpha: 0.8),
                      ]
                    : _isRecording
                    ? [
                        context.colors.error,
                        context.colors.error.withValues(alpha: 0.8),
                      ]
                    : [context.primary, context.primary.withValues(alpha: 0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (_isCountingDown
                              ? context.colors.tertiary
                              : _isRecording
                              ? context.colors.error
                              : context.primary)
                          .withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: _isCountingDown
                  ? Text(
                      '$_countdownSeconds',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isCountingDown
              ? 'Chuẩn bị...'
              : _isRecording
              ? 'Nhấn để dừng'
              : 'Nhấn để bắt đầu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isCountingDown
                ? context.colors.tertiary
                : _isRecording
                ? context.colors.error
                : context.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRecording
              ? 'Còn ${_maxRecordingDurationSeconds - _recordingDuration.inSeconds}s'
              : 'Tối đa ${_maxRecordingDurationSeconds}s',
          style: TextStyle(
            fontSize: 14,
            color: context.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingProgress() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.error.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.colors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Đang ghi âm',
                style: TextStyle(
                  fontSize: 18,
                  color: context.colors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formatDuration(_recordingDuration),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: context.colors.error,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:
                  _recordingDuration.inSeconds / _maxRecordingDurationSeconds,
              backgroundColor: context.colors.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.error),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.primary.withValues(alpha: 0.6),
          width: 2.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.primary, context.colors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: context.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Voice Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Powered by Gemini',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: _isPlaying
                      ? context.colors.tertiaryContainer
                      : context.colors.tertiary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isPlaying
                        ? context.colors.onTertiaryContainer
                        : context.colors.tertiary,
                    width: 2,
                  ),
                ),
                child: IconButton(
                  onPressed: _playRecording,
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isPlaying
                        ? context.colors.onTertiaryContainer
                        : context.colors.tertiary,
                  ),
                  tooltip: _isPlaying ? 'Tạm dừng' : 'Nghe audio',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildAnalysisItem(
            icon: Icons.mood_rounded,
            label: 'Cảm xúc',
            value: _audioAnalysis!['emotion'] ?? 'N/A',
            color: context.colors.error,
          ),
          const SizedBox(height: 14),
          _buildAnalysisItem(
            icon: Icons.graphic_eq_rounded,
            label: 'Chất giọng',
            value: _audioAnalysis!['voice_quality'] ?? 'N/A',
            color: context.primary,
          ),
          const SizedBox(height: 14),
          _buildAnalysisItem(
            icon: Icons.location_on_rounded,
            label: 'Vùng miền',
            value: _audioAnalysis!['accent'] ?? 'N/A',
            color: context.colors.secondary,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.tertiaryContainer,
                  context.colors.tertiary.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: context.colors.tertiary.withValues(alpha: 0.55),
                width: 2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.tertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.stars_rounded,
                    color: context.colors.tertiary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Overview',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.colors.tertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _audioAnalysis!['overview'] ?? 'Không có đánh giá',
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: context.onSurface.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.4),
                  color.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.onSurface.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.surfaceContainerHigh.withValues(alpha: 0.8),
            context.colors.surfaceContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.outline.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.tertiary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: context.colors.tertiary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Thời lượng: ${_formatDuration(_recordingDuration)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.colors.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
              activeTrackColor: context.primary,
              inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
              thumbColor: context.primary,
              overlayColor: context.primary.withValues(alpha: 0.3),
            ),
            child: Slider(
              value: _totalDuration.inMilliseconds > 0
                  ? _playbackPosition.inMilliseconds /
                        _totalDuration.inMilliseconds
                  : 0.0,
              onChanged: (value) {
                if (_totalDuration.inMilliseconds > 0) {
                  final newPosition = Duration(
                    milliseconds: (value * _totalDuration.inMilliseconds)
                        .toInt(),
                  );
                  _audioPlayer.seek(newPosition);
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_playbackPosition),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.onSurface.withValues(alpha: 0.8),
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _playRecording,
            icon: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 24,
            ),
            label: Text(
              _isPlaying ? 'Tạm dừng' : 'Phát audio',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _deleteRecording,
            icon: const Icon(Icons.refresh_rounded, size: 24),
            label: const Text(
              'Ghi lại',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.surfaceContainerHigh,
              foregroundColor: context.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _hasRecording ? widget.onNext : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasRecording ? context.primary : context.outline,
          foregroundColor: _hasRecording
              ? Colors.white
              : context.onSurface.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: _hasRecording ? 3 : 0,
        ),
        child: const Text(
          'Hoàn tất thiết lập',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  strokeWidth: 8,
                  valueColor: AlwaysStoppedAnimation<Color>(context.primary),
                ),
              ),
              const SizedBox(height: 28),
              Icon(Icons.psychology_rounded, color: context.primary, size: 56),
              const SizedBox(height: 20),
              Text(
                'AI đang phân tích',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Vui lòng đợi trong giây lát...',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        _buildHeader(),
                        const SizedBox(height: 28),

                        // Content based on state
                        if (!_hasRecording) ...[
                          // Recording mode
                          if (!_isRecording && !_isCountingDown) ...[
                            _buildPromptCard(),
                            const SizedBox(height: 32),
                          ],

                          Center(child: _buildRecordingButton()),

                          if (_isRecording) ...[
                            const SizedBox(height: 32),
                            _buildRecordingProgress(),
                          ],
                        ] else ...[
                          // Playback mode with analysis
                          if (_audioAnalysis != null) ...[
                            _buildAnalysisCard(),
                            const SizedBox(height: 20),
                          ],

                          _buildAudioPlayer(),
                          const SizedBox(height: 20),
                          _buildActionButtons(),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildCompleteButton(),
                ),
              ],
            ),

            // Loading overlay
            if (_isAnalyzingAudio) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }
}
