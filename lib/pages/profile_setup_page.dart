import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile_setup_data.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/pages/profile_setup/profile_details_step.dart';
import 'package:rizz_mobile/pages/profile_setup/gender_interest_step.dart';
import 'package:rizz_mobile/pages/profile_setup/looking_for_step.dart';
import 'package:rizz_mobile/pages/profile_setup/study_style_step.dart';
import 'package:rizz_mobile/pages/profile_setup/weekend_habit_step.dart';
import 'package:rizz_mobile/pages/profile_setup/interests_step.dart';
import 'package:rizz_mobile/pages/profile_setup/campus_life_step.dart';
import 'package:rizz_mobile/pages/profile_setup/after_graduation_step.dart';
import 'package:rizz_mobile/pages/profile_setup/communication_step.dart';
import 'package:rizz_mobile/pages/profile_setup/deal_breakers_step.dart';
import 'package:rizz_mobile/pages/profile_setup/photo_upload_step.dart';
import 'package:rizz_mobile/pages/profile_setup/profile_verification_step.dart';
import 'package:rizz_mobile/pages/profile_setup/voice_recording_step.dart';
import 'package:rizz_mobile/services/profile_setup_service.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final PageController _pageController = PageController();
  final ProfileSetupData _profileData = ProfileSetupData();
  int _currentStep = 0;

  final List<String> _stepTitles = [
    'Profile Details',
    'Gender Interest',
    'Looking For',
    'Study Style',
    'Weekend Habits',
    'Interests',
    'Campus Life',
    'After Graduation',
    'Communication',
    'Deal Breakers',
    'Photo Upload',
    'Profile Verification',
    'Voice Recording',
  ];

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeSetup() async {
    // Mark profile setup as complete
    await ProfileSetupService.completeProfileSetup();
    
    // Handle setup completion - navigate to main app or show success
    if (mounted) {
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
                  child: const Icon(Icons.check, color: Colors.green, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Profile Setup Complete!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to Rizz! Your profile is now ready to connect with others.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const BottomTabPage()),
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
                      'Start Connecting',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
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
      ProfileVerificationStep(profileData: _profileData, onNext: _nextStep),
      VoiceRecordingStep(profileData: _profileData, onNext: _nextStep),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: context.colors.onSurface),
                onPressed: _previousStep,
              )
            : null,
        title: Column(
          children: [
            Text(
              '${_currentStep + 1} of ${_stepTitles.length}',
              style: TextStyle(fontSize: 14, color: context.colors.onSurface),
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
    );
  }
}
