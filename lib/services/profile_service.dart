import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:rizz_mobile/models/profile.dart';

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
  Future<Profile> getProfile(String profileId) async {
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
        return Profile.fromJson(jsonData);
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
  final List<Profile> profiles;
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
    return ProfileResponse(
      profiles:
          (json['data'] as List<dynamic>?)
              ?.map(
                (profile) => Profile.fromJson(profile as Map<String, dynamic>),
              )
              .toList() ??
          [],
      currentPage: json['current_page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalProfiles: json['total'] as int? ?? 0,
      hasNextPage: json['has_next_page'] as bool? ?? false,
      hasPreviousPage: json['has_previous_page'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': profiles.map((profile) => profile.toJson()).toList(),
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
