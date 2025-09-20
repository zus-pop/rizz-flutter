import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/user_profile.dart';
import 'package:rizz_mobile/services/user_profile_service.dart';
import 'package:rizz_mobile/data/sample_profiles.dart';

enum LoadingState { idle, loading, loadingMore, success, error }

class UserProfileProvider extends ChangeNotifier {
  final UserProfileService _profileService = UserProfileService();

  // State
  List<UserProfile> _profiles = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  // Filters
  RangeValues _ageRange = const RangeValues(18, 65);
  double _maxDistance = 100.0;

  // Use sample data flag (for development/testing)
  bool _useSampleData = true; // Set to false when you have a real API

  // Getters
  List<UserProfile> get profiles => _profiles;
  LoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get hasNextPage => _hasNextPage;
  bool get isLoadingMore => _isLoadingMore;
  RangeValues get ageRange => _ageRange;
  double get maxDistance => _maxDistance;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isEmpty => _profiles.isEmpty;

  /// Initialize and load first page of profiles
  Future<void> initialize() async {
    if (_profiles.isNotEmpty) return; // Already initialized

    await loadProfiles(refresh: true);
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
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    List<UserProfile> filteredProfiles = sampleProfiles.where((profile) {
      bool ageMatch =
          profile.age >= _ageRange.start && profile.age <= _ageRange.end;
      bool distanceMatch = profile.distanceKm <= _maxDistance;
      return ageMatch && distanceMatch;
    }).toList();

    if (refresh) {
      _profiles = filteredProfiles;
    } else {
      // Simulate pagination - for demo, just return the same data
      _profiles.addAll(filteredProfiles);
    }

    _hasNextPage = false; // No more pages in sample data
    _setLoadingState(LoadingState.success);
  }

  /// Load from real API
  Future<void> _loadFromAPI(bool refresh) async {
    final response = await _profileService.getProfiles(
      page: _currentPage,
      limit: 10,
      ageMin: _ageRange.start.round(),
      ageMax: _ageRange.end.round(),
      maxDistance: _maxDistance,
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
      await loadProfiles(refresh: false);
    }
  }

  /// Refresh profiles (pull to refresh)
  Future<void> refreshProfiles() async {
    await loadProfiles(refresh: true);
  }

  /// Apply filters and reload
  Future<void> applyFilters({
    RangeValues? ageRange,
    double? maxDistance,
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

    if (filtersChanged) {
      await loadProfiles(refresh: true);
    }
  }

  /// Remove a profile (after swipe)
  void removeProfile(String profileId) {
    // _profiles.removeWhere((profile) => profile.id == profileId);
    // notifyListeners();
  }

  /// Like a profile
  Future<bool> likeProfile(String profileId) async {
    try {
      if (_useSampleData) {
        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 300));
        removeProfile(profileId);
        return true;
      } else {
        final success = await _profileService.likeProfile(profileId);
        if (success) {
          removeProfile(profileId);
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
        removeProfile(profileId);
        return true;
      } else {
        final success = await _profileService.passProfile(profileId);
        if (success) {
          removeProfile(profileId);
        }
        return success;
      }
    } catch (e) {
      debugPrint('Error passing profile: $e');
      return false;
    }
  }

  /// Get profile by ID
  UserProfile? getProfileById(String id) {
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

  @override
  void dispose() {
    super.dispose();
  }
}
