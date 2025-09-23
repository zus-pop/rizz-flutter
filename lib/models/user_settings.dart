import 'package:flutter/material.dart';

class UserSettings {
  final String? selectedUniversity;
  final String? selectedAfterGraduation;
  final String? selectedLoveLanguage;
  final String? selectedZodiac;
  final String? selectedGender;
  final String? selectedLookingFor;
  final Set<String> selectedInterests;
  final RangeValues ageRange;
  final double distance;
  final bool pushNotifications;

  const UserSettings({
    this.selectedUniversity,
    this.selectedAfterGraduation,
    this.selectedLoveLanguage,
    this.selectedZodiac,
    this.selectedGender,
    this.selectedLookingFor,
    this.selectedInterests = const {},
    this.ageRange = const RangeValues(18, 30),
    this.distance = 50,
    this.pushNotifications = true,
  });

  UserSettings copyWith({
    String? selectedUniversity,
    String? selectedAfterGraduation,
    String? selectedLoveLanguage,
    String? selectedZodiac,
    String? selectedGender,
    String? selectedLookingFor,
    Set<String>? selectedInterests,
    RangeValues? ageRange,
    double? distance,
    bool? pushNotifications,
    bool? darkMode,
  }) {
    return UserSettings(
      selectedUniversity: selectedUniversity ?? this.selectedUniversity,
      selectedAfterGraduation:
          selectedAfterGraduation ?? this.selectedAfterGraduation,
      selectedLoveLanguage: selectedLoveLanguage ?? this.selectedLoveLanguage,
      selectedZodiac: selectedZodiac ?? this.selectedZodiac,
      selectedGender: selectedGender ?? this.selectedGender,
      selectedLookingFor: selectedLookingFor ?? this.selectedLookingFor,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      ageRange: ageRange ?? this.ageRange,
      distance: distance ?? this.distance,
      pushNotifications: pushNotifications ?? this.pushNotifications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedUniversity': selectedUniversity,
      'selectedAfterGraduation': selectedAfterGraduation,
      'selectedLoveLanguage': selectedLoveLanguage,
      'selectedZodiac': selectedZodiac,
      'selectedGender': selectedGender,
      'selectedLookingFor': selectedLookingFor,
      'selectedInterests': selectedInterests.toList(),
      'ageRange': {'start': ageRange.start, 'end': ageRange.end},
      'distance': distance,
      'pushNotifications': pushNotifications,
    };
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      selectedUniversity: json['selectedUniversity'],
      selectedAfterGraduation: json['selectedAfterGraduation'],
      selectedLoveLanguage: json['selectedLoveLanguage'],
      selectedZodiac: json['selectedZodiac'],
      selectedGender: json['selectedGender'],
      selectedLookingFor: json['selectedLookingFor'],
      selectedInterests: Set<String>.from(json['selectedInterests'] ?? []),
      ageRange: json['ageRange'] != null
          ? RangeValues(
              json['ageRange']['start']?.toDouble() ?? 18,
              json['ageRange']['end']?.toDouble() ?? 30,
            )
          : const RangeValues(18, 30),
      distance: json['distance']?.toDouble() ?? 50,
      pushNotifications: json['pushNotifications'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.selectedUniversity == selectedUniversity &&
        other.selectedAfterGraduation == selectedAfterGraduation &&
        other.selectedLoveLanguage == selectedLoveLanguage &&
        other.selectedZodiac == selectedZodiac &&
        other.selectedGender == selectedGender &&
        other.selectedLookingFor == selectedLookingFor &&
        other.selectedInterests.length == selectedInterests.length &&
        other.selectedInterests.every(selectedInterests.contains) &&
        other.ageRange == ageRange &&
        other.distance == distance &&
        other.pushNotifications == pushNotifications;
  }

  @override
  int get hashCode {
    return Object.hash(
      selectedUniversity,
      selectedAfterGraduation,
      selectedLoveLanguage,
      selectedZodiac,
      selectedGender,
      selectedLookingFor,
      selectedInterests,
      ageRange,
      distance,
      pushNotifications,
    );
  }
}
