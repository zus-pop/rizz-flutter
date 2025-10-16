import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class VoiceRecordingPage extends StatefulWidget {
  const VoiceRecordingPage({super.key});

  @override
  State<VoiceRecordingPage> createState() => _VoiceRecordingPageState();
}

class _VoiceRecordingPageState extends State<VoiceRecordingPage>
    with TickerProviderStateMixin {
  // Audio related variables
  Duration get maxRecordingDuration {
    final authProvider = context.read<AuthenticationProvider>();
    return authProvider.isRizzPlus
        ? const Duration(hours: 1) // Unlimited for premium users
        : const Duration(seconds: 10);
  }

  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  bool _isAnalyzingAudio = false;
  bool _isUploadingAudio = false;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final GenerativeModel _model;
  Map<String, dynamic>? _audioAnalysis;
  File? _voiceRecording;
  String? _audioUrl; // For existing audio from Firestore

  // Animation controllers
  late AnimationController _pulseAnimationController;
  late AnimationController _waveformAnimationController;
  late AnimationController _analysisAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _setupAudioListeners();
    _setupAnimations();
    _loadExistingAudio();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _pulseAnimationController.dispose();
    _waveformAnimationController.dispose();
    _analysisAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    // Pulse animation for recording button
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Waveform animation
    _waveformAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Analysis animation
    _analysisAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  Future<void> _loadExistingAudio() async {
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final userId = authProvider.userId;

      if (userId == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final audioUrl = data['audioUrl'] as String?;
        final emotion = data['emotion'] as String?;
        final voiceQuality = data['voice_quality'] as String?;
        final accent = data['accent'] as String?;

        if (audioUrl != null &&
            emotion != null &&
            voiceQuality != null &&
            accent != null) {
          setState(() {
            _hasRecording = true;
            _audioUrl = audioUrl;
            _audioAnalysis = {
              'emotion': emotion,
              'voice_quality': voiceQuality,
              'accent': accent,
              'overview': 'Giọng nói hiện tại của bạn',
            };
          });

          // Set up audio player with existing URL
          await _audioPlayer.setSource(UrlSource(audioUrl));
          final duration = await _audioPlayer.getDuration();
          if (duration != null) {
            setState(() {
              _totalDuration = duration;
            });
          }

          _analysisAnimationController.forward(from: 0);
        }
      }
    } catch (e) {
      debugPrint('Error loading existing audio: $e');
    }
  }

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
            "Không xác định",
          ],
          description: 'Nguồn gốc của chất giọng trong audio',
        ),
        'overview': Schema.string(
          description:
              '1 câu đánh giá siêu ngắn gọn có thể pha thêm một chút vui nhộn của AI đối với audio, nói rõ giọng này là đến từ tỉnh nào nằm ở trong 8 tiểu vùng miền một chính xác nhất có thể nhưng đừng có cứng nhắc quá lúc nào cũng nhắc về vùng miền',
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

  void _setupAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _isPlaying = false;
            _playbackPosition = Duration.zero;
          }
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _playbackPosition = position;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: const Text('Giọng nói của bạn'),
        centerTitle: true,
        backgroundColor: context.colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Hero Section
              _buildHeroSection(),

              const SizedBox(height: 32),

              // Main Content
              if (!_hasRecording) ...[
                _buildRecordingInterface(),
              ] else ...[
                _buildPlaybackInterface(),
              ],

              const SizedBox(height: 32),

              // AI Analysis Section
              if (_audioAnalysis != null || _isAnalyzingAudio) ...[
                _buildAIAnalysisSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.primary.withValues(alpha: .1),
            context.primary.withValues(alpha: .05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.primary.withValues(alpha: .2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.mic, size: 48, color: context.primary),
          const SizedBox(height: 16),
          Text(
            'Thu âm giọng nói của bạn',
            style: AppTheme.headline3.copyWith(color: context.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'AI sẽ phân tích và đưa ra nhận xét về giọng nói của bạn',
            style: AppTheme.body2.copyWith(
              color: context.onSurface.withValues(alpha: .7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingInterface() {
    return Column(
      children: [
        // Recording Button with Animation
        AnimatedBuilder(
          animation: _pulseAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRecording
                  ? 1.0 + (_pulseAnimationController.value * 0.1)
                  : 1.0,
              child: GestureDetector(
                onTap: _record,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _isRecording
                        ? const LinearGradient(
                            colors: [Colors.red, Colors.redAccent],
                          )
                        : LinearGradient(
                            colors: [
                              context.primary,
                              context.primary.withValues(alpha: .8),
                            ],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : context.primary)
                            .withValues(alpha: .3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Recording Status
        Text(
          _isRecording
              ? 'Đang ghi âm... (${_getRemainingTimeText()})'
              : 'Nhấn để ghi âm giọng nói',
          style: AppTheme.headline4.copyWith(
            color: _isRecording ? Colors.red : context.onSurface,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Text(
          _isRecording
              ? _formatDuration(_recordingDuration)
              : _getMaxRecordingText(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isRecording
                ? Colors.red
                : context.onSurface.withValues(alpha: .7),
          ),
        ),

        // Progress bar for free users
        if (_isRecording &&
            !context.read<AuthenticationProvider>().isRizzPlus) ...[
          const SizedBox(height: 24),
          Container(
            width: 200,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor:
                  _recordingDuration.inSeconds / maxRecordingDuration.inSeconds,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaybackInterface() {
    return Column(
      children: [
        // Success Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.green.withValues(alpha: .3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Giọng nói đã được thu',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Audio Waveform Visualization
        Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHighest.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: AnimatedBuilder(
            animation: _waveformAnimationController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(double.infinity, 68),
                painter: AudioWaveformPainter(
                  progress: _waveformAnimationController.value,
                  isPlaying: _isPlaying,
                  color: context.primary,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Playback Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Play/Pause Button
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: context.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withValues(alpha: .3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _playRecording,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            const SizedBox(width: 32),

            // Record New Button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isAnalyzingAudio ? null : _startNewRecording,
                icon: const Icon(Icons.mic, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Time Display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDuration(_playbackPosition),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.onSurface.withValues(alpha: .7),
              ),
            ),
            Text(
              ' / ',
              style: TextStyle(
                fontSize: 16,
                color: context.onSurface.withValues(alpha: .5),
              ),
            ),
            Text(
              _formatDuration(_totalDuration),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.onSurface.withValues(alpha: .7),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Submit Button - Only show if user has newly recorded audio
        if (_voiceRecording != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isUploadingAudio || _isAnalyzingAudio)
                  ? null
                  : _submitAudio,
              icon: _isUploadingAudio
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _isAnalyzingAudio
                  ? const Icon(Icons.psychology)
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isUploadingAudio
                    ? 'Đang tải lên...'
                    : _isAnalyzingAudio
                    ? 'Đang phân tích...'
                    : 'Lưu giọng nói',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isUploadingAudio || _isAnalyzingAudio)
                    ? Colors.grey
                    : Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAIAnalysisSection() {
    if (_isAnalyzingAudio) {
      return AnimatedBuilder(
        animation: _analysisAnimationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: .1),
                  Colors.purple.withValues(alpha: .1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withValues(alpha: .3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Animated AI Icon
                Transform.rotate(
                  angle: _analysisAnimationController.value * 2 * pi,
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.blue,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'AI đang phân tích giọng nói...',
                  style: AppTheme.headline4.copyWith(color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng đợi trong giây lát',
                  style: TextStyle(
                    color: context.onSurface.withValues(alpha: .7),
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (_audioAnalysis == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _analysisAnimationController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: .1),
                Colors.pink.withValues(alpha: .1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.purple.withValues(alpha: .3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.smart_toy, color: Colors.purple, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Phân tích AI',
                    style: AppTheme.headline4.copyWith(color: Colors.purple),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Analysis Cards
              Row(
                children: [
                  Expanded(
                    child: _buildAnalysisCard(
                      'Cảm xúc',
                      _audioAnalysis!['emotion'] ?? 'N/A',
                      _getEmotionIcon(_audioAnalysis!['emotion'] ?? ''),
                      _getEmotionColor(_audioAnalysis!['emotion'] ?? ''),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAnalysisCard(
                      'Chất giọng',
                      _audioAnalysis!['voice_quality'] ?? 'N/A',
                      Icons.mic,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildAnalysisCard(
                'Vùng miền',
                _audioAnalysis!['accent'] ?? 'N/A',
                Icons.location_on,
                Colors.green,
                fullWidth: true,
              ),

              const SizedBox(height: 20),

              // AI Overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: .2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.purple,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _audioAnalysis!['overview'] ?? 'Không có đánh giá',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.purple.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Audio Methods
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
        (dir) => '${dir.path}/${_generateRandomId()}.wav',
      );

      _startTimer();
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: filePath,
      );
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _showSnackBar('Lỗi khi bắt đầu ghi âm');
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

        final authProvider = context.read<AuthenticationProvider>();
        if (!authProvider.isRizzPlus &&
            _recordingDuration.inSeconds >= maxRecordingDuration.inSeconds) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI đang phân tích giọng nói của bạn...'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue,
        ),
      );

      String? path = await _audioRecorder.stop();
      if (path == null) throw Exception('Path error for the recording');

      final file = File(path);
      _voiceRecording = file;
      _hasRecording = true;

      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
        _totalDuration = Duration.zero;
      });

      _analyzeAudioAsync(file);
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() {
        _isAnalyzingAudio = false;
      });
      _showSnackBar('Lỗi khi dừng ghi âm');
    }
  }

  Future<void> _analyzeAudioAsync(File file) async {
    try {
      final prompt = TextPart("Hãy phân tích giọng vùng miền trong audio này.");
      final audioBytes = await file.readAsBytes();
      final audioPart = InlineDataPart('audio/wav', audioBytes);

      final response = await _model.generateContent([
        Content.multi([prompt, audioPart]),
      ]);

      if (mounted) {
        try {
          if (response.text != null) {
            final jsonResponse = jsonDecode(response.text!);
            setState(() {
              _audioAnalysis = jsonResponse;
            });

            _analysisAnimationController.forward(from: 0);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI đã hoàn thành phân tích giọng nói!'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          setState(() {
            _audioAnalysis = {
              'emotion': 'N/A',
              'voice_quality': 'N/A',
              'accent': 'N/A',
              'overview': 'Không thể phân tích audio',
            };
          });
        } finally {
          setState(() {
            _isAnalyzingAudio = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error analyzing audio: $e');
      if (mounted) {
        setState(() {
          _isAnalyzingAudio = false;
          _audioAnalysis = {
            'emotion': 'N/A',
            'voice_quality': 'N/A',
            'accent': 'N/A',
            'overview': 'Không thể phân tích audio',
          };
        });
      }
    }
  }

  Future<void> _playRecording() async {
    if (_voiceRecording != null || _audioUrl != null) {
      try {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          if (_totalDuration.inMilliseconds > 0 &&
              _playbackPosition.inMilliseconds >=
                  _totalDuration.inMilliseconds - 100) {
            await _audioPlayer.stop();
            setState(() {
              _playbackPosition = Duration.zero;
            });
            // Play from local file or URL
            if (_voiceRecording != null) {
              await _audioPlayer.play(UrlSource(_voiceRecording!.path));
            } else if (_audioUrl != null) {
              await _audioPlayer.play(UrlSource(_audioUrl!));
            }
          } else {
            // Play from local file or URL
            if (_voiceRecording != null) {
              await _audioPlayer.play(UrlSource(_voiceRecording!.path));
            } else if (_audioUrl != null) {
              await _audioPlayer.play(UrlSource(_audioUrl!));
            }
          }
        }
      } catch (e) {
        _showSnackBar('Lỗi khi phát audio');
      }
    }
  }

  void _startNewRecording() {
    if (_isAnalyzingAudio) {
      _showSnackBar('Vui lòng đợi AI phân tích xong');
      return;
    }

    setState(() {
      _hasRecording = false;
      _recordingDuration = Duration.zero;
      _playbackPosition = Duration.zero;
      _totalDuration = Duration.zero;
      _audioAnalysis = null;
      _audioUrl = null; // Clear existing audio URL
    });
    _audioPlayer.stop();
  }

  Future<String> _uploadAudioToStorage(File audioFile) async {
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final String fileName = '${const Uuid().v4()}.wav';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('user_audio')
          .child(userId)
          .child(fileName);

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(audioFile);

      // Get download URL after upload completes
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading audio: $e');
      rethrow;
    }
  }

  Future<void> _submitAudio() async {
    if (_voiceRecording == null || _audioAnalysis == null) {
      _showSnackBar('Vui lòng đợi AI phân tích xong');
      return;
    }

    setState(() {
      _isUploadingAudio = true;
    });

    try {
      final authProvider = context.read<AuthenticationProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Upload audio to Firebase Storage first
      final audioUrl = await _uploadAudioToStorage(_voiceRecording!);

      // Update user document with audio data
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'audioUrl': audioUrl,
        'emotion': _audioAnalysis!['emotion'],
        'voice_quality': _audioAnalysis!['voice_quality'],
        'accent': _audioAnalysis!['accent'],
        'lastVoiceUpdate': FieldValue.serverTimestamp(),
      });

      _showSnackBar('Giọng nói đã được lưu thành công!');
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error saving voice recording: $e');
      _showSnackBar('Lỗi khi lưu giọng nói: $e');
    } finally {
      setState(() {
        _isUploadingAudio = false;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _getRemainingTimeText() {
    final authProvider = context.read<AuthenticationProvider>();
    if (authProvider.isRizzPlus) {
      return 'không giới hạn';
    }
    final remaining =
        maxRecordingDuration.inSeconds - _recordingDuration.inSeconds;
    return '${remaining}s còn lại';
  }

  String _getMaxRecordingText() {
    final authProvider = context.read<AuthenticationProvider>();
    if (authProvider.isRizzPlus) {
      return 'không giới hạn thời gian';
    }
    return 'tối đa ${maxRecordingDuration.inSeconds}s';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case 'Vui':
        return Colors.green;
      case 'Buồn':
        return Colors.blue;
      case 'Tự tin':
        return Colors.orange;
      case 'Lo lắng':
        return Colors.amber;
      case 'Trung lập':
        return Colors.grey;
      case 'Ngông':
        return Colors.pink;
      case 'Xấu hổ':
        return Colors.purple;
      case 'Rụt rè':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'Vui':
        return Icons.sentiment_very_satisfied;
      case 'Buồn':
        return Icons.sentiment_dissatisfied;
      case 'Tự tin':
        return Icons.star;
      case 'Lo lắng':
        return Icons.warning_amber;
      case 'Trung lập':
        return Icons.sentiment_neutral;
      case 'Ngông':
        return Icons.psychology;
      case 'Xấu hổ':
        return Icons.face;
      case 'Rụt rè':
        return Icons.person;
      default:
        return Icons.question_mark;
    }
  }
}

// Enhanced Audio Waveform Painter
class AudioWaveformPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;

  AudioWaveformPainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isPlaying ? color : color.withValues(alpha: .3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final int barCount = 50;
    final double barWidth = size.width / barCount;
    final double maxBarHeight = size.height * 0.8;

    final random = Random(42);

    for (int i = 0; i < barCount; i++) {
      final double normalizedPosition = i / barCount;
      final double offset = isPlaying
          ? sin((normalizedPosition + progress) * 12) * 0.3
          : 0;

      double barHeight;
      if (normalizedPosition < 0.1 || normalizedPosition > 0.9) {
        barHeight = maxBarHeight * 0.2 * (1 + offset);
      } else {
        barHeight =
            maxBarHeight * (0.2 + 0.8 * random.nextDouble()) * (1 + offset);
      }

      final double startY = size.height / 2 - barHeight / 2;
      final double endY = startY + barHeight;

      final double x = i * barWidth + barWidth / 2;

      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
