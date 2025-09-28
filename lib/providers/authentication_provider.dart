import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rizz_mobile/services/profile_setup_service.dart';

class AuthenticationProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isProfileSetupComplete = false;
  String? _phoneNumber;
  String? _userToken;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isProfileSetupComplete => _isProfileSetupComplete;
  String? get phoneNumber => _phoneNumber;
  String? get userToken => _userToken;

  static const String _isLoggedInKey = 'is_logged_in';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userTokenKey = 'user_token';

  // Initialize authentication state from storage
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    _phoneNumber = prefs.getString(_phoneNumberKey);
    _userToken = prefs.getString(_userTokenKey);
    _isProfileSetupComplete = await ProfileSetupService.isProfileSetupComplete();

    _isLoading = false;
    notifyListeners();
  }

  // Login with phone number
  Future<bool> loginWithPhone(String phoneNumber, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call for OTP verification
      await Future.delayed(const Duration(seconds: 2));
      
      // For demo purposes, accept any 6-digit OTP
      if (otp.length == 6) {
        _isLoggedIn = true;
        _phoneNumber = phoneNumber;
        _userToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';

        // Save to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_phoneNumberKey, phoneNumber);
        await prefs.setString(_userTokenKey, _userToken!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login with Google
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate Google sign in
      await Future.delayed(const Duration(seconds: 2));
      
      _isLoggedIn = true;
      _phoneNumber = null; // No phone for Google login
      _userToken = 'google_token_${DateTime.now().millisecondsSinceEpoch}';

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userTokenKey, _userToken!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_userTokenKey);
    // Also reset profile setup when logging out
    await ProfileSetupService.resetProfileSetup();

    _isLoggedIn = false;
    _isProfileSetupComplete = false;
    _phoneNumber = null;
    _userToken = null;

    _isLoading = false;
    notifyListeners();
  }

  // Update profile setup status
  Future<void> updateProfileSetupStatus() async {
    _isProfileSetupComplete = await ProfileSetupService.isProfileSetupComplete();
    notifyListeners();
  }
}