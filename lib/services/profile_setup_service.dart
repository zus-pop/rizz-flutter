import 'package:shared_preferences/shared_preferences.dart';

class ProfileSetupService {
  static const String _profileSetupCompleteKey = 'profile_setup_complete';

  // Check if profile setup is complete
  static Future<bool> isProfileSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profileSetupCompleteKey) ?? false;
  }

  // Mark profile setup as complete
  static Future<void> completeProfileSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_profileSetupCompleteKey, true);
  }

  // Reset profile setup (for testing purposes)
  static Future<void> resetProfileSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileSetupCompleteKey);
  }
}