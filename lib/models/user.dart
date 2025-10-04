import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final DateTime? birthday;
  final String? gender;
  final String? university;
  final String? bio;
  final String? interestedIn;
  final String? lookingFor;
  final String? studyStyle;
  final String? weekendHabit;
  final String? campusLife;
  final String? afterGraduation;
  final String? communicationPreference;
  final List<String>? dealBreakers;
  late List<String>? imageUrls;
  final List<String>? interests;
  late String? audioUrl; // Optional audio URL for voice messages
  final String? emotion; // AI-analyzed emotion from voice
  final String? voiceQuality; // AI-analyzed voice quality
  final String? accent;
  final bool? isCompleteSetup;

  User({
    this.email,
    this.firstName,
    this.lastName,
    this.birthday,
    this.gender,
    this.university,
    this.phone,
    this.bio,
    this.interestedIn,
    this.lookingFor,
    this.studyStyle,
    this.weekendHabit,
    this.campusLife,
    this.afterGraduation,
    this.communicationPreference,
    this.dealBreakers,
    this.imageUrls,
    this.interests,
    this.audioUrl,
    this.emotion,
    this.voiceQuality,
    this.accent,
    this.isCompleteSetup,
  });

  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return User(
      email: data?['email'] as String?,
      firstName: data?['firstName'] as String?,
      lastName: data?['lastName'] as String?,
      phone: data?['phone'] as String?,
      birthday: (data?['birthday'] as Timestamp?)?.toDate(),
      gender: data?['gender'] as String?,
      university: data?['university'] as String?,
      bio: data?['bio'] as String?,
      interestedIn: data?['interestedIn'] as String?,
      lookingFor: data?['lookingFor'] as String?,
      studyStyle: data?['studyStyle'] as String?,
      weekendHabit: data?['weekendHabit'] as String?,
      campusLife: data?['campusLife'] as String?,
      afterGraduation: data?['afterGraduation'] as String?,
      communicationPreference: data?['communicationPreference'] as String?,
      dealBreakers: (data?['dealBreakers'] as List<dynamic>?)?.cast<String>(),
      imageUrls: (data?['imageUrls'] as List<dynamic>?)?.cast<String>(),
      interests: (data?['interests'] as List<dynamic>?)?.cast<String>(),
      audioUrl: data?['audioUrl'] as String?,
      emotion: data?['emotion'] as String?,
      voiceQuality: data?['voiceQuality'] as String?,
      accent: data?['accent'] as String?,
      isCompleteSetup: data?['isCompleteSetup'] as bool?,
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> data = {};
    if (email != null) data['email'] = email;
    if (firstName != null) data['firstName'] = firstName;
    if (lastName != null) data['lastName'] = lastName;
    if (birthday != null) data['birthday'] = Timestamp.fromDate(birthday!);
    if (gender != null) data['gender'] = gender;
    if (university != null) data['university'] = university;
    if (phone != null) data['phone'] = phone;
    if (bio != null) data['bio'] = bio;
    if (interestedIn != null) data['interestedIn'] = interestedIn;
    if (lookingFor != null) data['lookingFor'] = lookingFor;
    if (studyStyle != null) data['studyStyle'] = studyStyle;
    if (weekendHabit != null) data['weekendHabit'] = weekendHabit;
    if (campusLife != null) data['campusLife'] = campusLife;
    if (afterGraduation != null) data['afterGraduation'] = afterGraduation;
    if (communicationPreference != null)
      data['communicationPreference'] = communicationPreference;
    if (dealBreakers != null) data['dealBreakers'] = dealBreakers;
    if (imageUrls != null) data['imageUrls'] = imageUrls;
    if (interests != null) data['interests'] = interests;
    if (audioUrl != null) data['audioUrl'] = audioUrl;
    if (emotion != null) data['emotion'] = emotion;
    if (voiceQuality != null) data['voiceQuality'] = voiceQuality;
    if (accent != null) data['accent'] = accent;
    if (isCompleteSetup != null) data['isCompleteSetup'] = isCompleteSetup;
    return data;
  }
}
