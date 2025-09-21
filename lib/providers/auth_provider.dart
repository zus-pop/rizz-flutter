import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rizz_mobile/services/push_notification_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

enum AuthMethod { google, phone }

class AuthProvider extends ChangeNotifier {
  // Secure storage instance
  static const _storage = FlutterSecureStorage();
  final _pushNotificationService = PushNotificationService();

  // State
  AuthState _authState = AuthState.initial;
  String? _userId;
  String? _accessToken;
  String? _refreshToken;
  AuthMethod? _authMethod;
  String? _phoneNumber;
  String? _email;
  String? _errorMessage;
  String? _pushToken;

  // Verification state
  bool _isVerifyingPhone = false;
  String? _verificationId;

  // Getters
  AuthState get authState => _authState;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isLoading => _authState == AuthState.loading;
  bool get hasError => _authState == AuthState.error;
  bool get isVerifyingPhone => _isVerifyingPhone;
  String? get userId => _userId;
  String? get accessToken => _accessToken;
  String? get phoneNumber => _phoneNumber;
  String? get email => _email;
  String? get errorMessage => _errorMessage;
  AuthMethod? get authMethod => _authMethod;
  String? get verificationId => _verificationId;
  String? get pushToken => _pushToken;

  Future<void> updateToken() async {
    final token = await _pushNotificationService.requestPushToken();
    if (token != null) {
      _pushToken = token;
    }
  }

  /// Initialize authentication on app start
  Future<void> initializeAuth() async {
    try {
      _setAuthState(AuthState.loading);

      final storedUserId = await _storage.read(key: 'user_id');
      final storedAccessToken = await _storage.read(key: 'access_token');
      final storedRefreshToken = await _storage.read(key: 'refresh_token');
      final storedAuthMethod = await _storage.read(key: 'auth_method');
      final storedPhoneNumber = await _storage.read(key: 'phone_number');
      final storedEmail = await _storage.read(key: 'email');

      if (storedUserId != null && storedAccessToken != null) {
        _userId = storedUserId;
        _accessToken = storedAccessToken;
        _refreshToken = storedRefreshToken;
        _phoneNumber = storedPhoneNumber;
        _email = storedEmail;

        if (storedAuthMethod != null) {
          _authMethod = AuthMethod.values.firstWhere(
            (method) => method.toString() == storedAuthMethod,
            orElse: () => AuthMethod.google,
          );
        }

        // Validate token (you might want to check with server)
        bool isValid = await _validateToken();
        if (isValid) {
          _setAuthState(AuthState.authenticated);
        } else {
          // Try to refresh token
          bool refreshed = await _refreshAccessToken();
          if (refreshed) {
            _setAuthState(AuthState.authenticated);
          } else {
            await logout();
          }
        }
      } else {
        _setAuthState(AuthState.unauthenticated);
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _setError('Failed to initialize authentication');
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setAuthState(AuthState.loading);
      _clearError();

      // TODO: Implement Google Sign-In
      // This is a placeholder - you'll need to integrate with google_sign_in package
      // GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      // if (googleUser != null) {
      //   GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      //   // Send token to your backend for verification and user creation
      //   final response = await _sendGoogleTokenToBackend(googleAuth.idToken);
      //   if (response.success) {
      //     await _saveAuthData(
      //       userId: response.userId,
      //       accessToken: response.accessToken,
      //       refreshToken: response.refreshToken,
      //       authMethod: AuthMethod.google,
      //       email: googleUser.email,
      //     );
      //     _setAuthState(AuthState.authenticated);
      //     return true;
      //   }
      // }

      // Simulated success for development
      await Future.delayed(const Duration(seconds: 2));
      await _saveAuthData(
        userId: 'google_user_123',
        accessToken: 'mock_google_access_token',
        refreshToken: 'mock_google_refresh_token',
        authMethod: AuthMethod.google,
        email: 'user@gmail.com',
      );
      _setAuthState(AuthState.authenticated);
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      _setError('Failed to sign in with Google');
      return false;
    }
  }

  /// Start phone number verification
  Future<bool> startPhoneVerification(String phoneNumber) async {
    try {
      _setAuthState(AuthState.loading);
      _clearError();
      _isVerifyingPhone = true;
      notifyListeners();

      // TODO: Implement phone verification with Firebase Auth or your backend
      // await FirebaseAuth.instance.verifyPhoneNumber(
      //   phoneNumber: phoneNumber,
      //   verificationCompleted: (credential) {
      //     // Auto verification completed
      //   },
      //   verificationFailed: (exception) {
      //     _setError(exception.message ?? 'Verification failed');
      //   },
      //   codeSent: (verificationId, resendToken) {
      //     _verificationId = verificationId;
      //   },
      //   codeAutoRetrievalTimeout: (verificationId) {
      //     _verificationId = verificationId;
      //   },
      // );

      // Simulated verification for development
      await Future.delayed(const Duration(seconds: 2));
      _verificationId = 'mock_verification_id';
      _phoneNumber = phoneNumber;
      _setAuthState(AuthState.unauthenticated); // Still need to verify code
      return true;
    } catch (e) {
      debugPrint('Error starting phone verification: $e');
      _setError('Failed to send verification code');
      _isVerifyingPhone = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify phone number with SMS code
  Future<bool> verifyPhoneCode(String smsCode) async {
    try {
      _setAuthState(AuthState.loading);
      _clearError();

      if (_verificationId == null) {
        _setError('No verification ID found');
        return false;
      }

      // TODO: Implement SMS code verification
      // PhoneAuthCredential credential = PhoneAuthProvider.credential(
      //   verificationId: _verificationId!,
      //   smsCode: smsCode,
      // );
      // UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      //
      // if (userCredential.user != null) {
      //   // Send token to your backend
      //   final response = await _sendPhoneTokenToBackend(userCredential.user!.uid);
      //   if (response.success) {
      //     await _saveAuthData(
      //       userId: response.userId,
      //       accessToken: response.accessToken,
      //       refreshToken: response.refreshToken,
      //       authMethod: AuthMethod.phone,
      //       phoneNumber: _phoneNumber,
      //     );
      //     _setAuthState(AuthState.authenticated);
      //     return true;
      //   }
      // }

      // Simulated success for development
      await Future.delayed(const Duration(seconds: 2));
      await _saveAuthData(
        userId: 'phone_user_123',
        accessToken: 'mock_phone_access_token',
        refreshToken: 'mock_phone_refresh_token',
        authMethod: AuthMethod.phone,
        phoneNumber: _phoneNumber,
      );
      _setAuthState(AuthState.authenticated);
      _isVerifyingPhone = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error verifying phone code: $e');
      _setError('Invalid verification code');
      return false;
    }
  }

  /// Resend SMS verification code
  Future<bool> resendVerificationCode() async {
    if (_phoneNumber == null) return false;
    return await startPhoneVerification(_phoneNumber!);
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // TODO: Call logout API if needed
      // await _logoutFromBackend();

      // Clear secure storage
      await _storage.deleteAll();

      // Clear state
      _userId = null;
      _accessToken = null;
      _refreshToken = null;
      _authMethod = null;
      _phoneNumber = null;
      _email = null;
      _verificationId = null;
      _isVerifyingPhone = false;

      _setAuthState(AuthState.unauthenticated);
    } catch (e) {
      debugPrint('Error during logout: $e');
      _setError('Failed to logout');
    }
  }

  /// Save authentication data to secure storage
  Future<void> _saveAuthData({
    required String userId,
    required String accessToken,
    String? refreshToken,
    required AuthMethod authMethod,
    String? phoneNumber,
    String? email,
  }) async {
    await _storage.write(key: 'user_id', value: userId);
    await _storage.write(key: 'access_token', value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
    await _storage.write(key: 'auth_method', value: authMethod.toString());
    if (phoneNumber != null) {
      await _storage.write(key: 'phone_number', value: phoneNumber);
    }
    if (email != null) {
      await _storage.write(key: 'email', value: email);
    }

    // Update state
    _userId = userId;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _authMethod = authMethod;
    _phoneNumber = phoneNumber;
    _email = email;
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

  /// Refresh access token using refresh token
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

  /// Set authentication state
  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _authState = AuthState.error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Cancel phone verification
  void cancelPhoneVerification() {
    _isVerifyingPhone = false;
    _verificationId = null;
    _phoneNumber = null;
    _setAuthState(AuthState.unauthenticated);
  }
}
