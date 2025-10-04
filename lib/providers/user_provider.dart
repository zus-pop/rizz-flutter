import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/user.dart';
import 'package:rizz_mobile/models/user_settings.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';

class UserProvider extends ChangeNotifier {
  final AuthenticationProvider _authProvider;

  // State
  User? _userProfile;
  UserSettings? _userSettings;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  // API base URL
  static const String baseUrl = 'https://api.example.com';

  UserProvider(this._authProvider);

  // Getters
  User? get userProfile => _userProfile;
  UserSettings? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasProfile => _userProfile != null;
  bool get hasSettings => _userSettings != null;

  // Profile getters
  String? get userName => _userProfile?.getFullName();
  int? get userAge => _userProfile?.getAge();
  String? get userBio => _userProfile?.bio;
  List<String> get userPhotos => _userProfile?.imageUrls ?? [];
  List<String> get userInterests => _userProfile?.interests ?? [];

  /// Initialize user data after authentication
  Future<void> initializeUserData() async {
    if (!_authProvider.isLoggedIn) return;

    try {
      _setLoading(true);
      _clearError();

      // Load user profile and settings concurrently
      await Future.wait([loadUserProfile(), loadUserSettings()]);
    } catch (e) {
      debugPrint('Error initializing user data: $e');
      _setError('Failed to load user data');
    } finally {
      _setLoading(false);
    }
  }

  /// Load user profile from API
  Future<void> loadUserProfile() async {
    if (!_authProvider.isLoggedIn) return;

    try {
      final token = await _authProvider.getValidAccessToken();
      if (token == null) {
        _setError('Authentication required');
        return;
      }

      // TODO: Replace with actual API call
      // final response = await http.get(
      //   Uri.parse('$baseUrl/users/me/profile'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   _userProfile = UserProfile.fromJson(data);
      //   notifyListeners();
      // } else {
      //   throw Exception('Failed to load profile: ${response.statusCode}');
      // }

      // Simulated API response for development
      await Future.delayed(const Duration(seconds: 1));
      _userProfile = User(
        id: 'user_123',
        firstName: 'John',
        lastName: 'Doe',
        email: 'johndoe@example.com',
        birthday: DateTime(1997, 5, 15),
        bio: 'Love adventure and good coffee ☕',
        imageUrls: [
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
        ],
        university: 'New York University',
        interests: ['Travel', 'Photography', 'Coffee', 'Hiking'],
        distanceKm: 0, // Distance to self is 0
        audioUrl: null,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _setError('Failed to load profile');
    }
  }

  /// Load user settings from API
  Future<void> loadUserSettings() async {
    if (!_authProvider.isLoggedIn) return;

    try {
      final token = await _authProvider.getValidAccessToken();
      if (token == null) {
        _setError('Authentication required');
        return;
      }

      // TODO: Replace with actual API call
      // final response = await http.get(
      //   Uri.parse('$baseUrl/users/me/settings'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   _userSettings = UserSettings.fromJson(data);
      //   notifyListeners();
      // } else {
      //   throw Exception('Failed to load settings: ${response.statusCode}');
      // }

      // Simulated API response for development
      await Future.delayed(const Duration(milliseconds: 500));
      _userSettings = UserSettings(
        selectedUniversity: 'MIT',
        selectedAfterGraduation: 'Full-time Job',
        selectedLoveLanguage: 'Quality Time',
        selectedZodiac: 'Leo',
        selectedGender: 'Male',
        selectedLookingFor: 'Long-term',
        selectedInterests: {'Travel', 'Food', 'Music'},
        ageRange: const RangeValues(22, 30),
        distance: 50.0,
        pushNotifications: true,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user settings: $e');
      _setError('Failed to load settings');
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? bio,
    List<String>? interests,
    List<String>? imageUrls,
  }) async {
    if (!_authProvider.isLoggedIn || _userProfile == null) return false;

    try {
      _setUpdating(true);
      _clearError();

      final token = await _authProvider.getValidAccessToken();
      if (token == null) {
        _setError('Authentication required');
        return false;
      }

      // Create updated profile with the same properties as the original
      // but override those that are provided as parameters
      final updatedProfile = User(
        id: _userProfile!.id,
        email: _userProfile!.email,
        firstName: firstName ?? _userProfile!.firstName,
        lastName: lastName ?? _userProfile!.lastName,
        birthday: _userProfile!.birthday,
        gender: _userProfile!.gender,
        university: _userProfile!.university,
        phone: _userProfile!.phone,
        bio: bio ?? _userProfile!.bio,
        interestedIn: _userProfile!.interestedIn,
        lookingFor: _userProfile!.lookingFor,
        studyStyle: _userProfile!.studyStyle,
        weekendHabit: _userProfile!.weekendHabit,
        campusLife: _userProfile!.campusLife,
        afterGraduation: _userProfile!.afterGraduation,
        communicationPreference: _userProfile!.communicationPreference,
        dealBreakers: _userProfile!.dealBreakers,
        imageUrls: imageUrls ?? _userProfile!.imageUrls,
        interests: interests ?? _userProfile!.interests,
        audioUrl: _userProfile!.audioUrl,
        emotion: _userProfile!.emotion,
        voiceQuality: _userProfile!.voiceQuality,
        accent: _userProfile!.accent,
        isCompleteSetup: _userProfile!.isCompleteSetup,
        distanceKm: _userProfile!.distanceKm,
      );

      // TODO: Replace with actual API call
      // final response = await http.put(
      //   Uri.parse('$baseUrl/users/me/profile'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      //   body: json.encode(updatedProfile.toJson()),
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   _userProfile = UserProfile.fromJson(data);
      //   notifyListeners();
      //   return true;
      // } else {
      //   throw Exception('Failed to update profile: ${response.statusCode}');
      // }

      // Simulated API response for development
      await Future.delayed(const Duration(seconds: 1));
      _userProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _setError('Failed to update profile');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Update user settings
  Future<bool> updateSettings(UserSettings newSettings) async {
    if (!_authProvider.isLoggedIn) return false;

    try {
      _setUpdating(true);
      _clearError();

      final token = await _authProvider.getValidAccessToken();
      if (token == null) {
        _setError('Authentication required');
        return false;
      }

      // TODO: Replace with actual API call
      // final response = await http.put(
      //   Uri.parse('$baseUrl/users/me/settings'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      //   body: json.encode(newSettings.toJson()),
      // );
      //
      // if (response.statusCode == 200) {
      //   final data = json.decode(response.body);
      //   _userSettings = UserSettings.fromJson(data);
      //   notifyListeners();
      //   return true;
      // } else {
      //   throw Exception('Failed to update settings: ${response.statusCode}');
      // }

      // Simulated API response for development
      await Future.delayed(const Duration(seconds: 1));
      _userSettings = newSettings;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating settings: $e');
      _setError('Failed to update settings');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Upload new profile photo
  Future<bool> uploadPhoto(String imagePath) async {
    if (!_authProvider.isLoggedIn || _userProfile == null) return false;

    try {
      _setUpdating(true);
      _clearError();

      final token = await _authProvider.getValidAccessToken();
      if (token == null) {
        _setError('Authentication required');
        return false;
      }

      // TODO: Replace with actual image upload
      // var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/me/photos'));
      // request.headers['Authorization'] = 'Bearer $token';
      // request.files.add(await http.MultipartFile.fromPath('photo', imagePath));
      //
      // var response = await request.send();
      // if (response.statusCode == 200) {
      //   var responseData = await response.stream.bytesToString();
      //   var data = json.decode(responseData);
      //   String newImageUrl = data['image_url'];
      //
      //   // Add new image to profile
      //   List<String> updatedImages = List.from(_userProfile!.imageUrls);
      //   updatedImages.add(newImageUrl);
      //
      //   _userProfile = _userProfile!.copyWith(imageUrls: updatedImages);
      //   notifyListeners();
      //   return true;
      // }

      // Simulated upload for development
      await Future.delayed(const Duration(seconds: 2));
      List<String> updatedImages = List.from(_userProfile!.imageUrls ?? []);
      updatedImages.add(
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500',
      );

      // Create updated profile with new image list
      final updatedProfile = User(
        id: _userProfile!.id,
        email: _userProfile!.email,
        firstName: _userProfile!.firstName,
        lastName: _userProfile!.lastName,
        birthday: _userProfile!.birthday,
        gender: _userProfile!.gender,
        university: _userProfile!.university,
        phone: _userProfile!.phone,
        bio: _userProfile!.bio,
        interestedIn: _userProfile!.interestedIn,
        lookingFor: _userProfile!.lookingFor,
        studyStyle: _userProfile!.studyStyle,
        weekendHabit: _userProfile!.weekendHabit,
        campusLife: _userProfile!.campusLife,
        afterGraduation: _userProfile!.afterGraduation,
        communicationPreference: _userProfile!.communicationPreference,
        dealBreakers: _userProfile!.dealBreakers,
        imageUrls: updatedImages,
        interests: _userProfile!.interests,
        audioUrl: _userProfile!.audioUrl,
        emotion: _userProfile!.emotion,
        voiceQuality: _userProfile!.voiceQuality,
        accent: _userProfile!.accent,
        isCompleteSetup: _userProfile!.isCompleteSetup,
        distanceKm: _userProfile!.distanceKm,
      );

      _userProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      _setError('Failed to upload photo');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Delete profile photo
  Future<bool> deletePhoto(String imageUrl) async {
    if (!_authProvider.isLoggedIn || _userProfile == null) return false;

    try {
      _setUpdating(true);
      _clearError();

      final token = await _authProvider.getValidAccessToken();
      if (token == null) {
        _setError('Authentication required');
        return false;
      }

      // TODO: Replace with actual API call
      // final response = await http.delete(
      //   Uri.parse('$baseUrl/users/me/photos'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      //   body: json.encode({'image_url': imageUrl}),
      // );
      //
      // if (response.statusCode == 200) {
      //   List<String> updatedImages = List.from(_userProfile!.imageUrls);
      //   updatedImages.remove(imageUrl);
      //
      //   _userProfile = _userProfile!.copyWith(imageUrls: updatedImages);
      //   notifyListeners();
      //   return true;
      // }

      // Simulated deletion for development
      await Future.delayed(const Duration(seconds: 1));
      List<String> updatedImages = List.from(_userProfile!.imageUrls ?? []);
      updatedImages.remove(imageUrl);

      // Create updated profile with new image list
      final updatedProfile = User(
        id: _userProfile!.id,
        email: _userProfile!.email,
        firstName: _userProfile!.firstName,
        lastName: _userProfile!.lastName,
        birthday: _userProfile!.birthday,
        gender: _userProfile!.gender,
        university: _userProfile!.university,
        phone: _userProfile!.phone,
        bio: _userProfile!.bio,
        interestedIn: _userProfile!.interestedIn,
        lookingFor: _userProfile!.lookingFor,
        studyStyle: _userProfile!.studyStyle,
        weekendHabit: _userProfile!.weekendHabit,
        campusLife: _userProfile!.campusLife,
        afterGraduation: _userProfile!.afterGraduation,
        communicationPreference: _userProfile!.communicationPreference,
        dealBreakers: _userProfile!.dealBreakers,
        imageUrls: updatedImages,
        interests: _userProfile!.interests,
        audioUrl: _userProfile!.audioUrl,
        emotion: _userProfile!.emotion,
        voiceQuality: _userProfile!.voiceQuality,
        accent: _userProfile!.accent,
        isCompleteSetup: _userProfile!.isCompleteSetup,
        distanceKm: _userProfile!.distanceKm,
      );

      _userProfile = updatedProfile;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      _setError('Failed to delete photo');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    if (!_authProvider.isLoggedIn) return false;

    try {
      _setUpdating(true);
      _clearError();

      final token = await _authProvider.getValidAccessToken();
      if (token == null) {
        _setError('Authentication required');
        return false;
      }

      // TODO: Replace with actual API call
      // final response = await http.delete(
      //   Uri.parse('$baseUrl/users/me'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      // );
      //
      // if (response.statusCode == 200) {
      //   // Clear user data and logout
      //   await clearUserData();
      //   await _authProvider.logout();
      //   return true;
      // }

      // Simulated deletion for development
      await Future.delayed(const Duration(seconds: 2));
      await clearUserData();
      await _authProvider.logout();
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      _setError('Failed to delete account');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Clear all user data (for logout)
  Future<void> clearUserData() async {
    _userProfile = null;
    _userSettings = null;
    _isLoading = false;
    _isUpdating = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh user data
  Future<void> refreshUserData() async {
    await initializeUserData();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set updating state
  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Get specific setting value
  T? getSetting<T>(String key) {
    if (_userSettings == null) return null;

    switch (key) {
      case 'ageRange':
        return _userSettings!.ageRange as T?;
      case 'distance':
        return _userSettings!.distance as T?;
      case 'selectedUniversity':
        return _userSettings!.selectedUniversity as T?;
      case 'selectedAfterGraduation':
        return _userSettings!.selectedAfterGraduation as T?;
      case 'selectedLoveLanguage':
        return _userSettings!.selectedLoveLanguage as T?;
      case 'selectedZodiac':
        return _userSettings!.selectedZodiac as T?;
      case 'selectedGender':
        return _userSettings!.selectedGender as T?;
      case 'selectedLookingFor':
        return _userSettings!.selectedLookingFor as T?;
      case 'selectedInterests':
        return _userSettings!.selectedInterests as T?;
      case 'pushNotifications':
        return _userSettings!.pushNotifications as T?;
      default:
        return null;
    }
  }
}
