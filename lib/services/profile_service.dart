import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:rizz_mobile/models/user.dart';

class ProfileService {
  static const String baseUrl =
      'https://api.example.com'; // Replace with your actual API URL
  static const String _profilesEndpoint = '/profiles';

  // Singleton pattern
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  /// Fetch user profiles with pagination
  /// [page] - Page number (starts from 1)
  /// [limit] - Number of profiles per page
  /// [ageMin] - Minimum age filter
  /// [ageMax] - Maximum age filter
  /// [maxDistance] - Maximum distance filter in kilometers
  /// [emotion] - Emotion filter for AI analysis
  /// [voiceQuality] - Voice quality filter for AI analysis
  /// [accent] - Accent filter for AI analysis
  Future<ProfileResponse> getProfiles({
    int page = 1,
    int limit = 10,
    int? ageMin,
    int? ageMax,
    double? maxDistance,
    String? emotion,
    String? voiceQuality,
    String? accent,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$_profilesEndpoint').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          if (ageMin != null) 'age_min': ageMin.toString(),
          if (ageMax != null) 'age_max': ageMax.toString(),
          if (maxDistance != null) 'max_distance': maxDistance.toString(),
          if (emotion != null) 'emotion': emotion,
          if (voiceQuality != null) 'voice_quality': voiceQuality,
          if (accent != null) 'accent': accent,
        },
      );

      debugPrint('Fetching profiles from: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              // Add authorization header if needed
              // 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return ProfileResponse.fromJson(jsonData);
      } else {
        throw ApiException(
          'Failed to fetch profiles: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error fetching profiles: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Get a single profile by ID
  Future<User> getProfile(String profileId) async {
    try {
      final uri = Uri.parse('$baseUrl$_profilesEndpoint/$profileId');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;

        // Create User manually from JSON data
        final user = User(
          id: profileId,
          firstName: jsonData['first_name'] as String?,
          lastName: jsonData['last_name'] as String?,
          email: jsonData['email'] as String?,
          birthday: jsonData['birthday'] != null
              ? DateTime.parse(jsonData['birthday'] as String)
              : null,
          gender: jsonData['gender'] as String?,
          university: jsonData['university'] as String?,
          bio: jsonData['bio'] as String?,
          imageUrls: jsonData['image_urls'] != null
              ? List<String>.from(jsonData['image_urls'] as List)
              : null,
          interests: jsonData['interests'] != null
              ? List<String>.from(jsonData['interests'] as List)
              : null,
          audioUrl: jsonData['audio_url'] as String?,
          emotion: jsonData['emotion'] as String?,
          voiceQuality: jsonData['voice_quality'] as String?,
          accent: jsonData['accent'] as String?,
        );

        return user;
      } else {
        throw ApiException(
          'Failed to fetch profile: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Like a profile
  Future<bool> likeProfile(String profileId) async {
    try {
      final uri = Uri.parse('$baseUrl$_profilesEndpoint/$profileId/like');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error liking profile: $e');
      return false;
    }
  }

  /// Pass a profile
  Future<bool> passProfile(String profileId) async {
    try {
      final uri = Uri.parse('$baseUrl$_profilesEndpoint/$profileId/pass');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error passing profile: $e');
      return false;
    }
  }

  /// Upload user voice recording
  Future<Map<String, dynamic>> uploadVoiceRecording({
    required File audioFile,
    required Map<String, dynamic> analysis,
    String? userId,
    Map<String, String>? additionalHeaders,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$_profilesEndpoint/voice');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll({
          'Accept': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer $token',
          ...?additionalHeaders, // Add custom headers
        });

      // Add audio file
      final audioStream = http.ByteStream(audioFile.openRead());
      final audioLength = await audioFile.length();
      final audioMultipartFile = http.MultipartFile(
        'audio',
        audioStream,
        audioLength,
        filename: 'voice_recording.wav',
      );
      request.files.add(audioMultipartFile);

      // Add analysis data as JSON string
      request.fields['analysis'] = jsonEncode(analysis);

      // Add user ID if provided
      if (userId != null) {
        request.fields['user_id'] = userId;
      }

      // Add additional data if provided
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          request.fields[key] = value.toString();
        });
      }

      debugPrint('Uploading voice recording to: $uri');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload response status: ${response.statusCode}');
      debugPrint('Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        throw ApiException(
          'Failed to upload voice recording: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error uploading voice recording: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }
}

/// Response model for paginated profiles
class ProfileResponse {
  final List<User> profiles;
  final int currentPage;
  final int totalPages;
  final int totalProfiles;
  final bool hasNextPage;
  final bool hasPreviousPage;

  ProfileResponse({
    required this.profiles,
    required this.currentPage,
    required this.totalPages,
    required this.totalProfiles,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final userProfiles = <User>[];
    final dataList = json['data'] as List<dynamic>? ?? [];

    for (var i = 0; i < dataList.length; i++) {
      final profile = dataList[i] as Map<String, dynamic>;
      final profileId = profile['id'] as String? ?? 'unknown-$i';

      // Create User manually from JSON data
      final user = User(
        id: profileId,
        firstName: profile['first_name'] as String?,
        lastName: profile['last_name'] as String?,
        email: profile['email'] as String?,
        birthday: profile['birthday'] != null
            ? DateTime.parse(profile['birthday'] as String)
            : null,
        gender: profile['gender'] as String?,
        university: profile['university'] as String?,
        bio: profile['bio'] as String?,
        imageUrls: profile['image_urls'] != null
            ? List<String>.from(profile['image_urls'] as List)
            : null,
        interests: profile['interests'] != null
            ? List<String>.from(profile['interests'] as List)
            : null,
        audioUrl: profile['audio_url'] as String?,
        emotion: profile['emotion'] as String?,
        voiceQuality: profile['voice_quality'] as String?,
        accent: profile['accent'] as String?,
        distanceKm: profile['distance_km'] as double?,
      );

      userProfiles.add(user);
    }

    return ProfileResponse(
      profiles: userProfiles,
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalProfiles: json['total'] as int? ?? 0,
      hasNextPage: json['has_next_page'] as bool? ?? false,
      hasPreviousPage: json['has_previous_page'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': profiles.map((profile) => profile.toFirestore()).toList(),
      'current_page': currentPage,
      'total_pages': totalPages,
      'total': totalProfiles,
      'has_next_page': hasNextPage,
      'has_previous_page': hasPreviousPage,
    };
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// Helper class to convert JSON to a DocumentSnapshot-like structure for User.fromFirestore
class JsonDocumentSnapshot {
  final String id;
  final Map<String, dynamic> data;

  JsonDocumentSnapshot(this.id, this.data);

  Map<String, dynamic> get() => data;
  String getId() => id;
}
