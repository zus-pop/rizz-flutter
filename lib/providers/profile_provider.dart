import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/user.dart';
import 'package:rizz_mobile/services/profile_service.dart';

enum LoadingState { idle, loading, loadingMore, success, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileService _profileService = ProfileService();

  // State
  List<User> _profiles = [];
  LoadingState _loadingState = LoadingState.idle;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoadingMore = false;

  // Filters
  RangeValues _ageRange = const RangeValues(18, 30);
  double _maxDistance = 100.0;
  String? _emotionFilter;
  String? _voiceQualityFilter;
  String? _accentFilter;
  String? _genderFilter;
  String? _universityFilter;
  List<String>? _interestsFilter;

  // Filtering state
  bool _isFilteringEnabled = false;
  DocumentSnapshot? _lastDocument;
  bool _currentUserIsPremium = false;

  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user info
  String? _currentUserId;

  // Liked profiles
  final List<User> _likedProfiles = [];

  // Passed users tracking
  Set<String> _passedUserIds = {};
  Set<String> _likedUserIds = {};

  // Getters
  List<User> get profiles => _profiles;
  LoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get hasNextPage => _hasNextPage;
  bool get isLoadingMore => _isLoadingMore;
  RangeValues get ageRange => _ageRange;
  double get maxDistance => _maxDistance;
  String? get emotionFilter => _emotionFilter;
  String? get voiceQualityFilter => _voiceQualityFilter;
  String? get accentFilter => _accentFilter;
  String? get genderFilter => _genderFilter;
  String? get universityFilter => _universityFilter;
  List<String>? get interestsFilter => _interestsFilter;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get hasError => _loadingState == LoadingState.error;
  bool get isEmpty => _profiles.isEmpty;
  List<User> get likedProfiles => _likedProfiles;
  bool get isFilteringEnabled => _isFilteringEnabled;
  String? get currentUserId => _currentUserId;

  /// Set current user ID
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  /// Toggle filtering on/off
  void toggleFiltering() {
    _isFilteringEnabled = !_isFilteringEnabled;
    notifyListeners();
    // Reload profiles when toggling filters
    loadProfiles(refresh: true);
  }

  /// Initialize and load first page of profiles
  Future<void> initialize() async {
    if (_profiles.isNotEmpty) return; // Already initialized

    // Load liked and passed user IDs
    await _loadUserInteractions();

    await loadProfiles(refresh: true);
  }

  /// Refresh all interaction data (liked, liked-by, matches)
  Future<void> refreshInteractions() async {
    await _loadUserInteractions();
    notifyListeners();
  }

  /// Load user interactions (liked and passed users)
  Future<void> _loadUserInteractions() async {
    if (_currentUserId == null) return;

    try {
      // Load liked users
      final likedSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('likes')
          .get();

      _likedUserIds = likedSnapshot.docs.map((doc) => doc.id).toSet();

      // Load passed users
      final passedSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('passes')
          .get();

      _passedUserIds = passedSnapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint('Error loading user interactions: $e');
    }
  }

  /// Load profiles with pagination
  Future<void> loadProfiles({bool refresh = false}) async {
    try {
      if (refresh) {
        _lastDocument = null;
        _hasNextPage = true;
        _profiles.clear();
        _setLoadingState(LoadingState.loading);
      } else if (_isLoadingMore || !_hasNextPage) {
        return; // Already loading more or no more pages
      } else {
        _isLoadingMore = true;
        _setLoadingState(LoadingState.loadingMore);
      }

      // Use Firestore
      await _loadFromFirestore(refresh);
    } catch (e) {
      debugPrint('Error loading profiles: $e');
      _errorMessage = e.toString();
      _setLoadingState(LoadingState.error);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Load profiles from Firestore
  Future<void> _loadFromFirestore(bool refresh) async {
    const int limit = 10;

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .where('isCompleteSetup', isEqualTo: true);

      // Exclude current user
      if (_currentUserId != null) {
        // Note: Firestore doesn't support != operator, so we'll filter client-side
      }

      // Apply filters only if filtering is enabled
      if (_isFilteringEnabled) {
        query = _applyFilters(query, isPremium: _currentUserIsPremium);
      }

      // Add pagination
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      query = query.limit(limit);

      final snapshot = await query.get();
      final users = <User>[];

      for (final doc in snapshot.docs) {
        final userId = doc.id;

        // Skip current user and already interacted users
        if (userId == _currentUserId ||
            _passedUserIds.contains(userId) ||
            _likedUserIds.contains(userId)) {
          continue;
        }

        final user = User.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );

        // Add the document ID and a placeholder distance
        // TODO: Calculate real distance based on geolocation
        final userWithData = user.copyWithId(userId).copyWithDistance(10.0);

        // Apply client-side age filtering if enabled
        if (_isFilteringEnabled && user.birthday != null) {
          final age = user.getAge();
          if (age < _ageRange.start || age > _ageRange.end) {
            continue;
          }
        }

        users.add(userWithData);
      }

      if (refresh) {
        _profiles = users;
      } else {
        _profiles.addAll(users);
      }

      _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasNextPage = snapshot.docs.length == limit;
      _setLoadingState(LoadingState.success);

      debugPrint('Loaded ${users.length} profiles from Firestore');
      debugPrint('Total profiles: ${_profiles.length}');
    } catch (e) {
      debugPrint('Error loading from Firestore: $e');
      rethrow;
    }
  }

  /// Apply filters to Firestore query
  Query<Map<String, dynamic>> _applyFilters(
    Query<Map<String, dynamic>> query, {
    bool isPremium = false,
  }) {
    // Premium filters - only apply if user is premium
    if (isPremium) {
      // Gender filter
      if (_genderFilter != null && _genderFilter!.isNotEmpty) {
        query = query.where('gender', isEqualTo: _genderFilter);
      }

      // University filter
      if (_universityFilter != null && _universityFilter!.isNotEmpty) {
        query = query.where('university', isEqualTo: _universityFilter);
      }

      // Interests filter (array-contains-any)
      if (_interestsFilter != null && _interestsFilter!.isNotEmpty) {
        query = query.where(
          'interests',
          arrayContainsAny: _interestsFilter!.take(10).toList(),
        );
      }
    }

    // Free filters - always available
    // Emotion filter
    if (_emotionFilter != null && _emotionFilter!.isNotEmpty) {
      query = query.where('emotion', isEqualTo: _emotionFilter);
    }

    // Voice quality filter
    if (_voiceQualityFilter != null && _voiceQualityFilter!.isNotEmpty) {
      query = query.where('voiceQuality', isEqualTo: _voiceQualityFilter);
    }

    // Accent filter
    if (_accentFilter != null && _accentFilter!.isNotEmpty) {
      query = query.where('accent', isEqualTo: _accentFilter);
    }

    return query;
  }

  /// Load sample data (for development)
  // Future<void> _loadSampleData(bool refresh) async {
  //   // Simulate realistic API delay
  //   await _simulateNetworkDelay();

  //   // Filter all sample profiles based on current filters
  //   List<Profile> filteredProfiles = sampleProfiles.where((profile) {
  //     bool ageMatch =
  //         profile.age >= _ageRange.start && profile.age <= _ageRange.end;
  //     bool distanceMatch = profile.distanceKm <= _maxDistance;
  //     bool emotionMatch =
  //         _emotionFilter == null || profile.emotion == _emotionFilter;
  //     bool voiceQualityMatch =
  //         _voiceQualityFilter == null ||
  //         profile.voiceQuality == _voiceQualityFilter;
  //     bool accentMatch =
  //         _accentFilter == null || profile.accent == _accentFilter;
  //     return ageMatch &&
  //         distanceMatch &&
  //         emotionMatch &&
  //         voiceQualityMatch &&
  //         accentMatch;
  //   }).toList();

  //   // Pagination settings
  //   const int profilesPerPage = 8; // Smaller page size for better testing
  //   int startIndex = (_currentPage - 1) * profilesPerPage;
  //   int endIndex = startIndex + profilesPerPage;

  //   // Get the profiles for current page
  //   List<Profile> pageProfiles = [];
  //   if (startIndex < filteredProfiles.length) {
  //     endIndex = endIndex > filteredProfiles.length
  //         ? filteredProfiles.length
  //         : endIndex;
  //     pageProfiles = filteredProfiles.sublist(startIndex, endIndex);
  //   }

  //   if (refresh) {
  //     _profiles = pageProfiles;
  //     _currentPage = 1;
  //   } else {
  //     _profiles.addAll(pageProfiles);
  //   }

  //   // Update pagination state
  //   _hasNextPage = endIndex < filteredProfiles.length;

  //   if (!refresh) {
  //     _currentPage++;
  //   }

  //   _setLoadingState(LoadingState.success);

  //   debugPrint('Loaded page $_currentPage: ${pageProfiles.length} profiles');
  //   debugPrint('Total profiles loaded: ${_profiles.length}');
  //   debugPrint('Has next page: $_hasNextPage');
  //   debugPrint('Filtered profiles available: ${filteredProfiles.length}');
  // }

  // /// Load from real API
  // /// Load more profiles (pagination)
  Future<void> loadMoreProfiles() async {
    if (_hasNextPage && !_isLoadingMore) {
      debugPrint('Loading more profiles... Current page: $_currentPage');
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
    String? emotion,
    String? voiceQuality,
    String? accent,
    String? gender,
    String? university,
    List<String>? interests,
    bool isPremium = false,
  }) async {
    bool filtersChanged = false;

    // if (ageRange != null && ageRange != _ageRange) {
    //   _ageRange = ageRange;
    //   filtersChanged = true;
    // }

    // if (maxDistance != null && maxDistance != _maxDistance) {
    //   _maxDistance = maxDistance;
    //   filtersChanged = true;
    // }

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

    // Only apply premium filters if user is premium
    if (isPremium) {
      if (gender != _genderFilter) {
        _genderFilter = gender;
        filtersChanged = true;
      }

      if (university != _universityFilter) {
        _universityFilter = university;
        filtersChanged = true;
      }

      if (interests != _interestsFilter) {
        _interestsFilter = interests;
        filtersChanged = true;
      }
    } else {
      // Clear premium filters for non-premium users
      if (_genderFilter != null) {
        _genderFilter = null;
        filtersChanged = true;
      }
      if (_universityFilter != null) {
        _universityFilter = null;
        filtersChanged = true;
      }
      if (_interestsFilter != null && _interestsFilter!.isNotEmpty) {
        _interestsFilter = null;
        filtersChanged = true;
      }
    }

    // Store premium status for use in _applyFilters
    _currentUserIsPremium = isPremium;

    if (filtersChanged) {
      await loadProfiles(refresh: true);
    }
  }

  /// Clear all filters
  void clearFilters() {
    _ageRange = const RangeValues(18, 30);
    _maxDistance = 100.0;
    _emotionFilter = null;
    _voiceQualityFilter = null;
    _accentFilter = null;
    _genderFilter = null;
    _universityFilter = null;
    _interestsFilter = null;

    loadProfiles(refresh: true);
  }

  /// Like a profile
  Future<bool> likeProfile(String profileId) async {
    try {
      if (_currentUserId == null) return false;
      // Use Firestore
      final batch = _firestore.batch();

      // Add like to current user's likes subcollection
      final likeRef = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('likes')
          .doc(profileId);

      batch.set(likeRef, {
        'timestamp': FieldValue.serverTimestamp(),
        'targetUserId': profileId,
      });

      // Check if target user also liked current user (potential match)
      final targetLikeDoc = await _firestore
          .collection('users')
          .doc(profileId)
          .collection('likes')
          .doc(_currentUserId!)
          .get();

      bool isMutual = targetLikeDoc.exists;

      if (isMutual) {
        // It's a match! Create match document in separate collection
        final sortedUsers = [_currentUserId!, profileId]..sort();
        final matchId = '${sortedUsers[0]}_${sortedUsers[1]}';

        // Check if match already exists (avoid duplicates)
        final existingMatch = await _firestore
            .collection('matches')
            .doc(matchId)
            .get();

        if (!existingMatch.exists) {
          final matchRef = _firestore.collection('matches').doc(matchId);
          batch.set(matchRef, {
            'users': sortedUsers,
            'timestamp': FieldValue.serverTimestamp(),
            'user1': sortedUsers[0],
            'user2': sortedUsers[1],
          });
        }
      }

      await batch.commit();

      // Add to local tracking
      _likedUserIds.add(profileId);

      // Return whether this created a mutual match
      return isMutual;
    } catch (e) {
      debugPrint('Error liking profile: $e');
      return false;
    }
  }

  /// Pass a profile
  Future<bool> passProfile(String profileId) async {
    try {
      if (_currentUserId == null) return false;

      // Use Firestore
      final batch = _firestore.batch();

      // Add pass to current user's passes subcollection
      final passRef = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('passes')
          .doc(profileId);

      batch.set(passRef, {
        'timestamp': FieldValue.serverTimestamp(),
        'targetUserId': profileId,
      });

      // Remove from likes collection if it exists (in case user previously liked and now passes)
      final likeRef = _firestore
          .collection('users')
          .doc(_currentUserId!)
          .collection('likes')
          .doc(profileId);

      // Check if like exists before deleting
      final likeDoc = await likeRef.get();
      if (likeDoc.exists) {
        batch.delete(likeRef);

        // Also remove any match if it exists
        final sortedUsers = [_currentUserId!, profileId]..sort();
        final matchId = '${sortedUsers[0]}_${sortedUsers[1]}';

        final matchRef = _firestore.collection('matches').doc(matchId);
        final matchDoc = await matchRef.get();

        if (matchDoc.exists) {
          batch.delete(matchRef);
        }
      }

      await batch.commit();

      // Update local tracking
      _passedUserIds.add(profileId);
      _likedUserIds.remove(profileId); // Remove from liked if it was there

      return true;
    } catch (e) {
      debugPrint('Error passing profile: $e');
      return false;
    }
  }

  /// Get profile by ID
  User? getProfileById(String id) {
    try {
      return _profiles.firstWhere((profile) => profile.id == id);
    } catch (e) {
      return null;
    }
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
      final success = await _profileService.passProfile(profileId);
      if (success) {
        removeLikedProfile(profileId);
      }
      return success;
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
      final result = await _profileService.uploadVoiceRecording(
        audioFile: audioFile,
        analysis: analysis,
        userId: userId,
        additionalHeaders: additionalHeaders,
        additionalData: additionalData,
      );
      return result;
    } catch (e) {
      debugPrint('Error uploading voice recording: $e');
      return null;
    }
  }
}
