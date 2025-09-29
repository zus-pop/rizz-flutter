import 'package:flutter/material.dart';
import 'package:rizz_mobile/services/auth_service.dart';
import 'package:rizz_mobile/services/firebase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rizz_mobile/services/profile_setup_service.dart';

class AuthenticationProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isProfileSetupComplete = false;
  String? _phoneNumber;
  String? _accessToken;
  String? _refreshToken;
  String? _pushToken;

  String? get pushToken => _pushToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isProfileSetupComplete => _isProfileSetupComplete;
  String? get phoneNumber => _phoneNumber;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userTokenKey = 'user_token';
  final _firebaseService = FirebaseService();
  final _authService = AuthService();

  // Initialize authentication state from storage
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    _phoneNumber = prefs.getString(_phoneNumberKey);
    _accessToken = prefs.getString(_userTokenKey);
    _isProfileSetupComplete =
        await ProfileSetupService.isProfileSetupComplete();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      // TODO: Call your backend to refresh token
      // final response = await http.post(
      //   Uri.parse('$baseUrl/auth/refresh'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({'refresh_token': _refreshToken}),
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   _accessToken = data['access_token'];
      //   _refreshToken = data['refresh_token'] ?? _refreshToken;
      //
      //   final prefs = await SharedPreferences.getInstance();
      //   await prefs.setString('access_token', _accessToken!);
      //   if (data['refresh_token'] != null) {
      //     await prefs.setString('refresh_token', _refreshToken!);
      //   }
      //   return true;
      // }

      // Simulated refresh for development
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  /// Get valid access token (refreshes if needed)
  Future<String?> getValidAccessToken() async {
    if (_accessToken == null) return null;

    bool isValid = await _validateToken();
    if (isValid) {
      return _accessToken;
    }

    bool refreshed = await _refreshAccessToken();
    if (refreshed) {
      return _accessToken;
    }

    // Token refresh failed, logout user
    await logout();
    return null;
  }

  /// Validate current access token
  Future<bool> _validateToken() async {
    if (_accessToken == null) return false;

    try {
      // TODO: Call your backend to validate token
      // final response = await http.get(
      //   Uri.parse('$baseUrl/auth/validate'),
      //   headers: {'Authorization': 'Bearer $_accessToken'},
      // );
      // return response.statusCode == 200;

      // Simulated validation for development
      await Future.delayed(const Duration(seconds: 1));
      return true;
    } catch (e) {
      debugPrint('Error validating token: $e');
      return false;
    }
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
        _accessToken = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';

        // Save to storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_phoneNumberKey, phoneNumber);
        await prefs.setString(_userTokenKey, _accessToken!);

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

  Future<void> updateToken() async {
    final token = await _firebaseService.requestPushToken();
    if (token != null) {
      _pushToken = token;
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate Google sign in
      final user = await _authService.signInWithGoogle();
      debugPrint(user.email);

      _isLoggedIn = true;
      _phoneNumber = null; // No phone for Google login
      _accessToken = 'google_token_${DateTime.now().millisecondsSinceEpoch}';

      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_userTokenKey, _accessToken!);

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

    await _authService.googleSignOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_userTokenKey);
    // Also reset profile setup when logging out
    await ProfileSetupService.resetProfileSetup();

    _isLoggedIn = false;
    _isProfileSetupComplete = false;
    _phoneNumber = null;
    _accessToken = null;

    _isLoading = false;
    notifyListeners();
  }

  // Update profile setup status
  Future<void> updateProfileSetupStatus() async {
    _isProfileSetupComplete =
        await ProfileSetupService.isProfileSetupComplete();
    notifyListeners();
  }
}
