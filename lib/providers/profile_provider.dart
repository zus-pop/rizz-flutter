import 'package:flutter/material.dart';
import 'dart:io';
import 'package:rizz_mobile/data/sample_profiles.dart';
import 'package:rizz_mobile/models/profile.dart';
import 'package:rizz_mobile/services/profile_service.dart';

enum LoadingState { idle, loading, loadingMore, success, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  // State
  List<Profile> _profiles = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  // Filters
  RangeValues _ageRange = const RangeValues(18, 65);
  double _maxDistance = 100.0;
  String? _emotionFilter;
  String? _voiceQualityFilter;
  String? _accentFilter;

  // Use sample data flag (for development/testing)
  bool _useSampleData = true; // Set to false when you have a real API

  // Liked profiles
  List<Profile> _likedProfiles = [];

  // Getters
  List<Profile> get profiles => _profiles;
  LoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get hasNextPage => _hasNextPage;
  bool get isLoadingMore => _isLoadingMore;
  RangeValues get ageRange => _ageRange;
  double get maxDistance => _maxDistance;
  String? get emotionFilter => _emotionFilter;
  String? get voiceQualityFilter => _voiceQualityFilter;
  String? get accentFilter => _accentFilter;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isEmpty => _profiles.isEmpty;
  List<Profile> get likedProfiles => _likedProfiles;

  /// Initialize and load first page of profiles
  Future<void> initialize() async {
    if (_profiles.isNotEmpty) return; // Already initialized

    // Initialize with some sample liked profiles for testing
    if (_useSampleData && _likedProfiles.isEmpty) {
      _initializeSampleLikedProfiles();
    }

    await loadProfiles(refresh: true);
  }

  /// Initialize sample liked profiles for testing
  void _initializeSampleLikedProfiles() {
    // Add first 6 sample profiles as liked for demo purposes
    _likedProfiles = sampleProfiles.take(6).toList();
    notifyListeners();
  }

  /// Load profiles with pagination
  Future<void> loadProfiles({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _hasNextPage = true;
        _profiles.clear();
        _setLoadingState(LoadingState.loading);
      } else if (_isLoadingMore || !_hasNextPage) {
        return; // Already loading more or no more pages
      } else {
        _isLoadingMore = true;
        _setLoadingState(LoadingState.loadingMore);
      }

      if (_useSampleData) {
        // Use sample data for development
        await _loadSampleData(refresh);
      } else {
        // Use real API
        await _loadFromAPI(refresh);
      }
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      _errorMessage = e.toString();
      _setLoadingState(LoadingState.error);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Load sample data (for development)
  Future<void> _loadSampleData(bool refresh) async {
    // Simulate realistic API delay
    await _simulateNetworkDelay();

    // Filter all sample profiles based on current filters
    List<Profile> filteredProfiles = sampleProfiles.where((profile) {
      bool ageMatch =
          profile.age >= _ageRange.start && profile.age <= _ageRange.end;
      bool distanceMatch = profile.distanceKm <= _maxDistance;
      bool emotionMatch =
          _emotionFilter == null || profile.emotion == _emotionFilter;
      bool voiceQualityMatch =
          _voiceQualityFilter == null ||
          profile.voiceQuality == _voiceQualityFilter;
      bool accentMatch =
          _accentFilter == null || profile.accent == _accentFilter;
      return ageMatch &&
          distanceMatch &&
          emotionMatch &&
          voiceQualityMatch &&
          accentMatch;
    }).toList();

    // Pagination settings
    const int profilesPerPage = 8; // Smaller page size for better testing
    int startIndex = (_currentPage - 1) * profilesPerPage;
    int endIndex = startIndex + profilesPerPage;

    // Get the profiles for current page
    List<Profile> pageProfiles = [];
    if (startIndex < filteredProfiles.length) {
      endIndex = endIndex > filteredProfiles.length
          ? filteredProfiles.length
          : endIndex;
      pageProfiles = filteredProfiles.sublist(startIndex, endIndex);
    }

    if (refresh) {
      _profiles = pageProfiles;
      _currentPage = 1;
    } else {
      _profiles.addAll(pageProfiles);
    }

    // Update pagination state
    _hasNextPage = endIndex < filteredProfiles.length;

    if (!refresh) {
      _currentPage++;
    }

    _setLoadingState(LoadingState.success);

    debugPrint('Loaded page $_currentPage: ${pageProfiles.length} profiles');
    debugPrint('Total profiles loaded: ${_profiles.length}');
    debugPrint('Has next page: $_hasNextPage');
    debugPrint('Filtered profiles available: ${filteredProfiles.length}');
  }

  /// Load from real API
  Future<void> _loadFromAPI(bool refresh) async {
    final response = await _profileService.getProfiles(
      page: _currentPage,
      limit: 10,
      ageMin: _ageRange.start.round(),
      ageMax: _ageRange.end.round(),
      maxDistance: _maxDistance,
      emotion: _emotionFilter,
      voiceQuality: _voiceQualityFilter,
      accent: _accentFilter,
    );

    if (refresh) {
      _profiles = response.profiles;
    } else {
      _profiles.addAll(response.profiles);
    }

    _currentPage = response.currentPage + 1;
    _hasNextPage = response.hasNextPage;
    _setLoadingState(LoadingState.success);
  }

  /// Load more profiles (pagination)
  Future<void> loadMoreProfiles() async {
    if (_hasNextPage && !_isLoadingMore) {
      debugPrint('Loading more profiles... Current page: $_currentPage');
      await loadProfiles(refresh: false);
    }
  }

  /// Simulate network delay for more realistic testing
  Future<void> _simulateNetworkDelay() async {
    // Random delay between 500ms and 1.5s to simulate real network
    final delay = 500 + (DateTime.now().millisecondsSinceEpoch % 1000);
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Refresh profiles (pull to refresh)
  Future<void> refreshProfiles() async {
    await loadProfiles(refresh: true);
  }

  /// Apply filters and reload
  Future<void> applyFilters({
    RangeValues? ageRange,
    double? maxDistance,
    String? emotion,
    String? voiceQuality,
    String? accent,
  }) async {
    bool filtersChanged = false;

    if (ageRange != null && ageRange != _ageRange) {
      _ageRange = ageRange;
      filtersChanged = true;
    }

    if (maxDistance != null && maxDistance != _maxDistance) {
      _maxDistance = maxDistance;
      filtersChanged = true;
    }

    if (emotion != _emotionFilter) {
      _emotionFilter = emotion;
      filtersChanged = true;
    }

    if (voiceQuality != _voiceQualityFilter) {
      _voiceQualityFilter = voiceQuality;
      filtersChanged = true;
    }

    if (accent != _accentFilter) {
      _accentFilter = accent;
      filtersChanged = true;
    }

    if (filtersChanged) {
      await loadProfiles(refresh: true);
    }
  }

  /// Like a profile
  Future<bool> likeProfile(String profileId) async {
    try {
      if (_useSampleData) {
        // Simulate API call and add to liked profiles
        await Future.delayed(const Duration(milliseconds: 300));

        // Find and add profile to liked list if not already liked
        final profile = getProfileById(profileId);
        if (profile != null && !_likedProfiles.any((p) => p.id == profileId)) {
          _likedProfiles.add(profile);
          notifyListeners();
        }
        return true;
      } else {
        final success = await _profileService.likeProfile(profileId);
        if (success) {
          // Add to liked profiles if API call successful
          final profile = getProfileById(profileId);
          if (profile != null &&
              !_likedProfiles.any((p) => p.id == profileId)) {
            _likedProfiles.add(profile);
            notifyListeners();
          }
        }
        return success;
      }
    } catch (e) {
      debugPrint('Error liking profile: $e');
      return false;
    }
  }

  /// Pass a profile
  Future<bool> passProfile(String profileId) async {
    try {
      if (_useSampleData) {
        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      } else {
        final success = await _profileService.passProfile(profileId);
        return success;
      }
    } catch (e) {
      debugPrint('Error passing profile: $e');
      return false;
    }
  }

  /// Get profile by ID
  Profile? getProfileById(String id) {
    try {
      return _profiles.firstWhere((profile) => profile.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Toggle between sample data and API
  void toggleDataSource() {
    _useSampleData = !_useSampleData;
    loadProfiles(refresh: true);
  }

  /// Clear all data
  void clearProfiles() {
    _profiles.clear();
    _currentPage = 1;
    _hasNextPage = true;
    _setLoadingState(LoadingState.idle);
    notifyListeners();
  }

  /// Set loading state and notify listeners
  void _setLoadingState(LoadingState state) {
    _loadingState = state;
    if (state != LoadingState.error) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Retry loading after error
  Future<void> retry() async {
    await loadProfiles(refresh: true);
  }

  /// Remove profile from liked list
  void removeLikedProfile(String profileId) {
    _likedProfiles.removeWhere((profile) => profile.id == profileId);
    notifyListeners();
  }

  /// Pass a liked profile (remove from liked list)
  Future<bool> passLikedProfile(String profileId) async {
    try {
      if (_useSampleData) {
        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 300));
        removeLikedProfile(profileId);
        return true;
      } else {
        final success = await _profileService.passProfile(profileId);
        if (success) {
          removeLikedProfile(profileId);
        }
        return success;
      }
    } catch (e) {
      debugPrint('Error passing liked profile: $e');
      return false;
    }
  }

  /// Upload voice recording to server (customizable)
  Future<Map<String, dynamic>?> uploadVoiceRecording({
    required File audioFile,
    required Map<String, dynamic> analysis,
    String? userId,
    Map<String, String>? additionalHeaders,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (_useSampleData) {
        // Simulate upload for development
        await Future.delayed(const Duration(seconds: 2));
        return {
          'success': true,
          'audio_url': 'https://example.com/sample_audio.wav',
          'message': 'Voice recording uploaded successfully',
        };
      } else {
        final result = await _profileService.uploadVoiceRecording(
          audioFile: audioFile,
          analysis: analysis,
          userId: userId,
          additionalHeaders: additionalHeaders,
          additionalData: additionalData,
        );
        return result;
      }
    } catch (e) {
      debugPrint('Error uploading voice recording: $e');
      return null;
    }
  }
}
