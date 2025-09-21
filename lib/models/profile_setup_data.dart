import 'dart:io';

class ProfileSetupData {
  // Profile Details
  String? firstName;
  String? lastName;
  DateTime? birthday;
  String? gender;
  String? university;

  // Preferences
  String? interestedIn;
  String? lookingFor;
  String? studyStyle;
  String? weekendHabit;
  List<String> interests = [];
  String? campusLife;
  String? afterGraduation;
  String? communicationPreference;
  List<String> dealBreakers = [];

  // Media
  List<File> photos = [];
  File? verificationPhoto;
  File? voiceRecording;

  ProfileSetupData();

  // Convert to Map for API
  Map<String, dynamic> toJson() {
    return {
      'profile_details': {
        'first_name': firstName,
        'last_name': lastName,
        'birthday': birthday?.toIso8601String(),
        'gender': gender,
        'university': university,
        'interested_in': interestedIn,
        'study_style': studyStyle,
        'weekend_habit': weekendHabit,
        'campus_life': campusLife,
        'after_graduation': afterGraduation,
        'communication_preference': communicationPreference,
        'deal_breakers': dealBreakers,
      },
      'preferences': {'looking_for': lookingFor, 'interests': interests},
      // Files will be handled separately in multipart upload
    };
  }

  // Validation methods
  bool get isProfileDetailsComplete {
    return firstName != null &&
        lastName != null &&
        birthday != null &&
        gender != null &&
        university != null &&
        interestedIn != null &&
        studyStyle != null &&
        weekendHabit != null &&
        campusLife != null &&
        afterGraduation != null &&
        communicationPreference != null &&
        dealBreakers.isNotEmpty;
  }

  bool get isPreferencesComplete {
    return lookingFor != null && interests.isNotEmpty;
  }

  bool get isMediaComplete {
    return photos.isNotEmpty && verificationPhoto != null;
  }

  bool get isComplete {
    return isProfileDetailsComplete && isPreferencesComplete && isMediaComplete;
  }

  double get completionPercentage {
    int completed = 0;
    int total = 13; // Total steps

    // Profile details (11 fields)
    if (firstName != null &&
        lastName != null &&
        birthday != null &&
        gender != null &&
        university != null)
      completed++;
    if (interestedIn != null) completed++;
    if (studyStyle != null) completed++;
    if (weekendHabit != null) completed++;
    if (campusLife != null) completed++;
    if (afterGraduation != null) completed++;
    if (communicationPreference != null) completed++;
    if (dealBreakers.isNotEmpty) completed++;

    // Preferences (2 fields)
    if (lookingFor != null) completed++;
    if (interests.isNotEmpty) completed++;

    // Media
    if (photos.isNotEmpty) completed++;
    if (verificationPhoto != null) completed++;
    if (voiceRecording != null) completed++;

    return completed / total;
  }
}
