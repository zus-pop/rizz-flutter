import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:record/record.dart';
import 'package:rizz_mobile/pages/settings_page.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile>
    with
        AutomaticKeepAliveClientMixin<Profile>,
        TickerProviderStateMixin<Profile> {
  List<String> selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Animation controller for badge gradient
  late AnimationController _gradientAnimationController;

  // Audio related variables
  // Free: 8 seconds, Plus: 15 seconds
  Duration get maxRecordingDuration {
    final authProvider = context.read<AuthenticationProvider>();
    return authProvider.isRizzPlus
        ? const Duration(seconds: 15)
        : const Duration(seconds: 8);
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
  // Store previous recording for backup
  File? _previousVoiceRecording;
  Map<String, dynamic>? _previousAudioAnalysis;
  Duration _previousRecordingDuration = Duration.zero;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _setupAudioListeners();

    // Initialize gradient animation (4 seconds for smooth sweeping shimmer)
    _gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _gradientAnimationController.dispose();
    super.dispose();
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

  void _pickImage() async {
    if (selectedImages.length >= 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 6 images allowed')));
      return;
    }

    // Show bottom sheet to choose between camera and gallery
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: context.primary),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: context.primary),
                title: const Text('Chọn từ kho ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _pickImageFromSource(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null && mounted) {
      setState(() {
        selectedImages.add(image.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        final isRizzPlus = authProvider.isRizzPlus;
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 50.0),
                    child: Column(
                      children: [
                        // Profile Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hồ sơ',
                              style: AppTheme.headline3.copyWith(
                                color: context.onSurface,
                                fontSize: 33,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _navigateToSettings(context),
                              icon: Icon(
                                Icons.settings,
                                color: context.onSurface,
                                size: 33,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Profile Avatar with Verification
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.primary,
                                    width: 3,
                                  ),
                                ),
                                child: selectedImages.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: selectedImages.first,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                          placeholder: (context, url) =>
                                              Container(
                                                color: context.primary
                                                    .withValues(alpha: 0.1),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: context.primary,
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color: context.primary
                                                    .withValues(alpha: 0.1),
                                                child: Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: context.primary,
                                                ),
                                              ),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            50,
                                          ),
                                          color: context.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 60,
                                          color: context.primary,
                                        ),
                                      ),
                              ),
                              // Verification badge
                              // Positioned(
                              //   bottom: 0,
                              //   right: 0,
                              //   child: Container(
                              //     width: 36,
                              //     height: 36,
                              //     decoration: BoxDecoration(
                              //       color: Colors.blue,
                              //       shape: BoxShape.circle,
                              //       border: Border.all(
                              //         color: Colors.white,
                              //         width: 2,
                              //       ),
                              //     ),
                              //     child: const Icon(
                              //       Icons.verified,
                              //       color: Colors.white,
                              //       size: 18,
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Profile Name
                        Text(
                          'John Doe, 22',
                          style: AppTheme.headline3.copyWith(
                            color: context.onSurface,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Rizz Plus Section - Conditional based on plan
                        if (isRizzPlus) ...[
                          // Premium User - Show Benefits
                          AnimatedBuilder(
                            animation: _gradientAnimationController,
                            builder: (context, child) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.lerp(
                                        const Color(0xFFff6ec7), // Bright pink
                                        const Color(
                                          0xFFffffff,
                                        ), // White highlight
                                        _gradientAnimationController.value *
                                            0.2,
                                      )!,
                                      const Color(0xFFfa5eff), // Main pink
                                      Color.lerp(
                                        const Color(0xFFc71585), // Deep pink
                                        const Color(
                                          0xFFffffff,
                                        ), // White highlight
                                        _gradientAnimationController.value *
                                            0.15,
                                      )!,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFfa5eff,
                                      ).withValues(alpha: 0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.workspace_premium,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Rizz Plus Active',
                                          style: AppTheme.headline4.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildPremiumFeature(
                                      Icons.mic,
                                      'Ghi âm lên đến 15 giây',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildPremiumFeature(
                                      Icons.smart_toy,
                                      'AI gợi ý tin nhắn khi chat',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildPremiumFeature(
                                      Icons.visibility,
                                      'Xem chi tiết hồ sơ đầy đủ',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          // Free User - Upgrade Prompt
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  context.primary,
                                  context.primary.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Upgrade to Rizz Plus',
                                      style: AppTheme.headline4.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Nâng cấp để mở khóa:',
                                  style: AppTheme.body2.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildUpgradeFeature(
                                  Icons.mic,
                                  'Ghi âm lên đến 15 giây',
                                ),
                                const SizedBox(height: 8),
                                _buildUpgradeFeature(
                                  Icons.smart_toy,
                                  'AI gợi ý tin nhắn khi chat',
                                ),
                                const SizedBox(height: 8),
                                _buildUpgradeFeature(
                                  Icons.visibility,
                                  'Xem chi tiết hồ sơ đầy đủ',
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      final status =
                                          await RevenueCatUI.presentPaywallIfNeeded(
                                            "premium",
                                            displayCloseButton: true,
                                          );
                                      if (status == PaywallResult.purchased) {
                                        authProvider.isRizzPlus = true;
                                      } else if (status ==
                                          PaywallResult.restored) {
                                        debugPrint("Restored");
                                      } else {
                                        debugPrint("No purchased occur");
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: context.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Nâng cấp ngay',
                                      style: AppTheme.button,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Audio Section (moved up)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: context.outline.withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Giọng của bạn',
                                    style: AppTheme.headline4.copyWith(
                                      color: context.onSurface,
                                    ),
                                  ),
                                  if (_hasRecording) ...[
                                    const Spacer(),
                                    Text(
                                      'Thời gian: ${_formatDuration(_recordingDuration)}',
                                      style: AppTheme.body2.copyWith(
                                        color: context.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (!_hasRecording) ...[
                                // Recording Interface
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: _record,
                                      child: Container(
                                        width: 80,
                                        height: 80,
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
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _isRecording
                                          ? 'Đang ghi âm... (${maxRecordingDuration.inSeconds - _recordingDuration.inSeconds}s remaining)'
                                          : 'Nhấn để ghi âm (tối đa ${maxRecordingDuration.inSeconds}s)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: _isRecording
                                            ? Colors.red
                                            : context.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (_isRecording) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: 150,
                                        child: LinearProgressIndicator(
                                          value:
                                              _recordingDuration.inSeconds /
                                              maxRecordingDuration.inSeconds,
                                          backgroundColor: Colors.grey
                                              .withValues(alpha: 0.3),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.red),
                                          minHeight: 4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatDuration(_recordingDuration),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Cancel button when recording new audio
                                      if (_previousVoiceRecording != null) ...[
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: _cancelNewRecording,
                                            icon: const Icon(Icons.cancel),
                                            label: const Text(
                                              'Cancel & Keep Current',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ] else ...[
                                // Playback Interface with option to record new
                                Column(
                                  children: [
                                    // Success indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Giọng nói đã được thu',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Show AI Analysis when available or analyzing
                                    if (_audioAnalysis != null ||
                                        _isAnalyzingAudio) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: _isAnalyzingAudio
                                              ? Colors.blue.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.purple.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _isAnalyzingAudio
                                                ? Colors.blue.withValues(
                                                    alpha: 0.3,
                                                  )
                                                : Colors.purple.withValues(
                                                    alpha: 0.3,
                                                  ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  _isAnalyzingAudio
                                                      ? Icons.psychology
                                                      : Icons.smart_toy,
                                                  color: _isAnalyzingAudio
                                                      ? Colors.blue
                                                      : Colors.purple,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _isAnalyzingAudio
                                                      ? 'AI đang phân tích...'
                                                      : 'AI Analysis',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: _isAnalyzingAudio
                                                        ? Colors.blue
                                                        : Colors.purple,
                                                  ),
                                                ),
                                                if (_isAnalyzingAudio) ...[
                                                  const SizedBox(width: 8),
                                                  const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.blue),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (_isAnalyzingAudio) ...[
                                              const SizedBox(height: 12),
                                              const Text(
                                                'Vui lòng đợi trong giây lát...',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.blue,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ] else if (_audioAnalysis !=
                                                null) ...[
                                              const SizedBox(height: 12),
                                              _buildAnalysisRow(
                                                'Cảm xúc:',
                                                _audioAnalysis!['emotion'] ??
                                                    'N/A',
                                              ),
                                              const SizedBox(height: 6),
                                              _buildAnalysisRow(
                                                'Chất giọng:',
                                                _audioAnalysis!['voice_quality'] ??
                                                    'N/A',
                                              ),
                                              const SizedBox(height: 6),
                                              _buildAnalysisRow(
                                                'Vùng miền:',
                                                _audioAnalysis!['accent'] ??
                                                    'N/A',
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple
                                                      .withValues(alpha: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.lightbulb,
                                                      color: Colors.purple,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        _audioAnalysis!['overview'] ??
                                                            'Không có đánh giá',
                                                        style: const TextStyle(
                                                          fontSize: 13,
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
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 16),

                                    // Playback Progress
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context
                                            .colors
                                            .surfaceContainerHigh
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          // Progress Bar
                                          SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              trackHeight: 4,
                                              thumbShape:
                                                  const RoundSliderThumbShape(
                                                    enabledThumbRadius: 6,
                                                  ),
                                              overlayShape:
                                                  const RoundSliderOverlayShape(
                                                    overlayRadius: 12,
                                                  ),
                                            ),
                                            child: Slider(
                                              value:
                                                  _totalDuration
                                                          .inMilliseconds >
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
                                                  _audioPlayer.seek(
                                                    newPosition,
                                                  );
                                                }
                                              },
                                              activeColor: context.primary,
                                              inactiveColor: Colors.grey
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
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
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: context.onSurface
                                                      .withValues(alpha: 0.7),
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(_totalDuration),
                                                style: TextStyle(
                                                  fontSize: 12,
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

                                    const SizedBox(height: 16),

                                    // Playback Controls
                                    Column(
                                      children: [
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
                                                  backgroundColor:
                                                      context.primary,
                                                  foregroundColor:
                                                      context.colors.onPrimary,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Submit Button
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed:
                                                    (_isUploadingAudio ||
                                                        _isAnalyzingAudio)
                                                    ? null
                                                    : _submitAudio,
                                                icon: _isUploadingAudio
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                Color
                                                              >(Colors.white),
                                                        ),
                                                      )
                                                    : _isAnalyzingAudio
                                                    ? const Icon(
                                                        Icons.psychology,
                                                      )
                                                    : const Icon(
                                                        Icons.cloud_upload,
                                                      ),
                                                label: Text(
                                                  _isUploadingAudio
                                                      ? 'Uploading...'
                                                      : _isAnalyzingAudio
                                                      ? 'Analyzing...'
                                                      : 'Submit',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      (_isUploadingAudio ||
                                                          _isAnalyzingAudio)
                                                      ? Colors.grey
                                                      : Colors.green,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Record New Button (full width)
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: _isAnalyzingAudio
                                                ? null
                                                : _startNewRecording,
                                            icon: const Icon(Icons.mic),
                                            label: Text(
                                              _isAnalyzingAudio
                                                  ? 'Analyzing Audio...'
                                                  : 'Record New Audio',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _isAnalyzingAudio
                                                  ? Colors.grey
                                                  : Colors.orange,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
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

                        const SizedBox(height: 24),

                        // Photo Grid (moved down)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: context.outline.withValues(alpha: 0.5),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ảnh',
                                    style: AppTheme.headline4.copyWith(
                                      color: context.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '${selectedImages.length}/6',
                                    style: AppTheme.body2.copyWith(
                                      color: context.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1,
                                    ),
                                itemCount: 6,
                                itemBuilder: (context, index) {
                                  if (index < selectedImages.length) {
                                    return Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: context.outline.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: selectedImages[index],
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: context.primary
                                                        .withValues(alpha: 0.1),
                                                    child: Icon(
                                                      Icons.image,
                                                      color: context.primary,
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (
                                                    context,
                                                    url,
                                                    error,
                                                  ) => Container(
                                                    color: context.primary
                                                        .withValues(alpha: 0.1),
                                                    child: Icon(
                                                      Icons.image,
                                                      color: context.primary,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(index),
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: context.outline.withValues(
                                              alpha: 0.5,
                                            ),
                                            style: BorderStyle.solid,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          color: context.primary,
                                          size: 32,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Quick Actions
                        Column(
                          children: [
                            _buildQuickAction(
                              'Những người tôi thích',
                              'Xem ai bạn đã thích',
                              Icons.favorite_outline,
                              _viewMyLikes,
                            ),
                            _buildQuickAction(
                              'Người dùng bị chặn',
                              'Quản lý hồ sơ bị chặn',
                              Icons.block_outlined,
                              _viewBlockedUsers,
                            ),
                            _buildQuickAction(
                              'Trợ giúp & Hỗ trợ',
                              'Nhận trợ giúp hoặc liên hệ hỗ trợ',
                              Icons.help_outline,
                              _getHelp,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Loading Overlay when uploading (removed blocking overlay for analysis)
              if (_isUploadingAudio) ...[
                Container(
                  height: double.infinity,
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
                            Icons.cloud_upload,
                            color: Colors.blue,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Đang tải lên giọng nói của bạn...',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vui lòng đợi trong khi tải lên',
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
        );
      },
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(Icons.check_circle, color: Colors.white, size: 18),
      ],
    );
  }

  Widget _buildUpgradeFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFfa5eff).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'PLUS',
            style: TextStyle(
              color: Color(0xFFfa5eff),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: context.outline.withValues(alpha: 1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: context.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.body2.copyWith(
                          color: context.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.onSurface.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewMyLikes() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('My likes coming soon!')));
  }

  void _viewBlockedUsers() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Blocked users coming soon!')));
  }

  void _getHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & support coming soon!')),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  // Audio methods
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

        if (_recordingDuration.inSeconds >= maxRecordingDuration.inSeconds) {
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

      // Show toast message for AI analysis
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI đang phân tích giọng nói của bạn...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      String? path = await _audioRecorder.stop();

      if (path == null) throw UnimplementedError('Path error for the record');

      final file = File(path);
      _voiceRecording = file;
      _hasRecording = true;

      // Reset audio player state for immediate playback
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
        _totalDuration = Duration.zero;
      });

      // Start AI analysis asynchronously
      _analyzeAudioAsync(file);
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

  Future<void> _analyzeAudioAsync(File file) async {
    try {
      final prompt = TextPart("Hãy phân tích giọng vùng miền trong audio này.");
      final audio = await file.readAsBytes();
      final audioPart = InlineDataPart('audio/mpeg', audio);
      final response = await _model.generateContent([
        Content.multi([prompt, audioPart]),
      ]);
      debugPrint(response.text);

      if (mounted) {
        try {
          if (response.text != null) {
            final jsonResponse = jsonDecode(response.text!);
            setState(() {
              _audioAnalysis = jsonResponse;
            });

            // Show success toast when analysis completes
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AI đã hoàn thành phân tích giọng nói!'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
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
            'overview': 'Không thể phân tích audio',
          };
        });
      }
    }
  }

  Future<void> _playRecording() async {
    if (_voiceRecording != null) {
      try {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          // If audio has completed (position is at the end), restart from beginning
          // Otherwise, resume from current position
          if (_totalDuration.inMilliseconds > 0 &&
              _playbackPosition.inMilliseconds >=
                  _totalDuration.inMilliseconds - 100) {
            // Audio completed, restart from beginning
            await _audioPlayer.stop();
            setState(() {
              _playbackPosition = Duration.zero;
            });
            await _audioPlayer.play(UrlSource(_voiceRecording!.path));
          } else {
            // Resume from current position (audio is paused or stopped but not completed)
            await _audioPlayer.play(UrlSource(_voiceRecording!.path));
          }
        }
      } catch (e) {
        debugPrint('Error playing recording: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing audio: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _startNewRecording() {
    // Prevent starting new recording while AI analysis is in progress
    if (_isAnalyzingAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đợi AI phân tích xong trước khi ghi âm mới'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Backup current recording
    _previousVoiceRecording = _voiceRecording;
    _previousAudioAnalysis = _audioAnalysis;
    _previousRecordingDuration = _recordingDuration;

    // Switch to recording mode
    setState(() {
      _hasRecording = false; // Show recording interface
      _recordingDuration = Duration.zero;
      _playbackPosition = Duration.zero;
      _totalDuration = Duration.zero;
    });
    _audioPlayer.stop();
  }

  Future<void> _cancelRecording() async {
    try {
      setState(() {
        _isRecording = false;
      });
      // Stop recording without AI analysis
      await _audioRecorder.stop();
      // Don't do AI analysis - just discard the recording
    } catch (e) {
      debugPrint('Error canceling recording: $e');
    }
  }

  void _cancelNewRecording() {
    // Don't allow canceling if AI analysis is in progress
    if (_isAnalyzingAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đợi AI phân tích xong trước khi hủy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Stop the current recording without AI analysis
    if (_isRecording) {
      _cancelRecording();
    }

    // Restore previous recording
    _voiceRecording = _previousVoiceRecording;
    _audioAnalysis = _previousAudioAnalysis;
    _recordingDuration = _previousRecordingDuration;

    setState(() {
      _hasRecording = _voiceRecording != null;
      _recordingDuration = _previousRecordingDuration;
      _isRecording = false; // Ensure recording state is reset
    });

    // Clear backup
    _previousVoiceRecording = null;
    _previousAudioAnalysis = null;
    _previousRecordingDuration = Duration.zero;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _submitAudio() async {
    if (_voiceRecording == null || _audioAnalysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đợi AI phân tích xong trước khi gửi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isAnalyzingAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI đang phân tích, vui lòng đợi...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploadingAudio = true;
    });

    try {
      final profileProvider = context.read<ProfileProvider>();
      final result = await profileProvider.uploadVoiceRecording(
        audioFile: _voiceRecording!,
        analysis: _audioAnalysis!,
        userId: 'current_user_id', // Replace with actual user ID from auth
        // You can customize these parameters as needed:
        // additionalHeaders: {'Custom-Header': 'value'},
        // additionalData: {'custom_field': 'value'},
      );

      // Handle the result yourself - you have full control here
      if (result != null) {
        debugPrint('Audio upload result: $result');

        // Example: Check if upload was successful
        if (result['success'] == true) {
          // Do something on success - navigate, update UI, etc.
          debugPrint('Upload successful! Audio URL: ${result['audio_url']}');

          // Example: Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'Audio uploaded successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Handle failure case
          throw Exception('Upload failed: ${result['message']}');
        }
      } else {
        throw Exception('No response from server');
      }
    } catch (e) {
      debugPrint('Error in submit audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAudio = false;
        });
      }
    }
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
}
