import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/models/user.dart';
import 'package:rizz_mobile/pages/profile_setup/after_graduation_step.dart';
import 'package:rizz_mobile/pages/profile_setup/campus_life_step.dart';
import 'package:rizz_mobile/pages/profile_setup/communication_step.dart';
import 'package:rizz_mobile/pages/profile_setup/deal_breakers_step.dart';
import 'package:rizz_mobile/pages/profile_setup/gender_interest_step.dart';
import 'package:rizz_mobile/pages/profile_setup/interests_step.dart';
import 'package:rizz_mobile/pages/profile_setup/looking_for_step.dart';
import 'package:rizz_mobile/pages/profile_setup/photo_upload_step.dart';
import 'package:rizz_mobile/pages/profile_setup/profile_details_step.dart';
import 'package:rizz_mobile/pages/profile_setup/study_style_step.dart';
import 'package:rizz_mobile/pages/profile_setup/voice_recording_step.dart';
import 'package:rizz_mobile/pages/profile_setup/weekend_habit_step.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/services/firebase_database_service.dart';
import 'package:rizz_mobile/services/firebase_service.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final PageController _pageController = PageController();
  final ProfileSetupData _profileData = ProfileSetupData();
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseDatabaseService _firebaseDatabaseService =
      FirebaseDatabaseService();
  int _currentStep = 0;
  bool _isLoading = false; // Track loading state during setup completion

  final List<String> _stepTitles = [
    'Thông tin hồ sơ',
    'Giới tính bạn muốn tìm',
    'Bạn đang tìm kiếm',
    'Phong cách học tập',
    'Thói quen cuối tuần',
    'Sở thích',
    'Cuộc sống tại trường',
    'Sau khi tốt nghiệp',
    'Giao tiếp',
    'Điều không chấp nhận',
    'Tải ảnh lên',
    'Ghi âm giọng nói',
  ];

  void _nextStep() {
    if (_isLoading) return; // Don't proceed if already loading

    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // On final step, complete the setup
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_isLoading || _currentStep <= 0) {
      return; // Don't allow going back if loading or at first step
    }

    setState(() {
      _currentStep--;
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Check if all required data is present for profile completion
  bool get _canCompleteSetup {
    // Use the model's built-in validation
    return _profileData.isComplete;
  }

  void _completeSetup() async {
    // Validate if user is logged in
    final userId = context.read<AuthenticationProvider>().userId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập trước')));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    // Double check that we have all required data
    if (!_canCompleteSetup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng hoàn thành tất cả các bước thiết lập'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Start loading state
    setState(() {
      _isLoading = true;
    });

    try {
      final updateUser = User(
        firstName: _profileData.firstName,
        lastName: _profileData.lastName,
        gender: _profileData.gender,
        university: _profileData.university,
        interestedIn: _profileData.interestedIn,
        lookingFor: _profileData.lookingFor,
        studyStyle: _profileData.studyStyle,
        weekendHabit: _profileData.weekendHabit,
        interests: _profileData.interests,
        campusLife: _profileData.campusLife,
        afterGraduation: _profileData.afterGraduation,
        communicationPreference: _profileData.communicationPreference,
        dealBreakers: _profileData.dealBreakers,
        accent: _profileData.accent,
        voiceQuality: _profileData.voiceQuality,
        emotion: _profileData.emotion,
        isCompleteSetup: true,
        birthday: _profileData.birthday,
      );

      // Upload photos
      if (_profileData.photos.isNotEmpty) {
        List<String> imageUrls = [];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        for (int i = 0; i < _profileData.photos.length; i++) {
          var photo = _profileData.photos[i];
          String fileName = 'profile_${userId}_${timestamp}_$i.jpg';
          final url = await _firebaseService.uploadFile(photo, fileName);
          if (url != null) {
            imageUrls.add(url);
          }
        }
        updateUser.imageUrls = imageUrls;
      }

      // Upload voice recording
      if (_profileData.voiceRecording != null) {
        String extension = p.extension(_profileData.voiceRecording!.path);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        String voiceFileName = 'voice_${userId}_$timestamp$extension';
        final voiceUrl = await _firebaseService.uploadFile(
          _profileData.voiceRecording!,
          voiceFileName,
        );
        updateUser.audioUrl = voiceUrl;
      }

      // Update user data in Firestore
      await _firebaseDatabaseService.updateUser(userId, updateUser);

      // Stop loading and show success dialog
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hoàn tất thiết lập hồ sơ!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chào mừng bạn đến với Rizz! Hồ sơ của bạn đã sẵn sàng để kết nối với mọi người.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFfa5eff),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Bắt đầu kết nối',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      // Handle errors during setup completion
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi hoàn tất thiết lập: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      VoiceRecordingStep(profileData: _profileData, onNext: _nextStep),
      ProfileDetailsStep(profileData: _profileData, onNext: _nextStep),
      GenderInterestStep(profileData: _profileData, onNext: _nextStep),
      LookingForStep(profileData: _profileData, onNext: _nextStep),
      StudyStyleStep(profileData: _profileData, onNext: _nextStep),
      WeekendHabitStep(profileData: _profileData, onNext: _nextStep),
      InterestsStep(profileData: _profileData, onNext: _nextStep),
      CampusLifeStep(profileData: _profileData, onNext: _nextStep),
      AfterGraduationStep(profileData: _profileData, onNext: _nextStep),
      CommunicationStep(profileData: _profileData, onNext: _nextStep),
      DealBreakersStep(profileData: _profileData, onNext: _nextStep),
      PhotoUploadStep(profileData: _profileData, onNext: _nextStep),
    ];

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: context.colors.surface,
            elevation: 0,
            leading: _currentStep > 0 && !_isLoading
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.colors.onSurface,
                    ),
                    onPressed: _previousStep,
                  )
                : null,
            title: Column(
              children: [
                Text(
                  '${_currentStep + 1} of ${_stepTitles.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _stepTitles.length,
                  backgroundColor: context.colors.onSurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFfa5eff),
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Prevent swiping
            children: steps,
          ),
        ),

        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: .5),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFfa5eff),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Đang hoàn tất hồ sơ của bạn...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đang tải ảnh và ghi âm lên máy chủ.\nVui lòng đợi trong giây lát.',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
