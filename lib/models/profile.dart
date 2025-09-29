class Profile {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> imageUrls;
  final String location;
  final List<String> interests;
  final double distanceKm; // Distance in kilometers
  final String? audioUrl; // Optional audio URL for voice messages
  final String? emotion; // AI-analyzed emotion from voice
  final String? voiceQuality; // AI-analyzed voice quality
  final String? accent; // AI-analyzed accent/region

  Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrls,
    required this.location,
    required this.interests,
    required this.distanceKm,
    this.audioUrl,
    this.emotion,
    this.voiceQuality,
    this.accent,
  });

  // Create a sample user profile
  factory Profile.sample({
    required String id,
    required String name,
    required int age,
    required String bio,
    required List<String> imageUrls,
    required String location,
    required List<String> interests,
    required double distanceKm,
    String? audioUrl,
    String? emotion,
    String? voiceQuality,
    String? accent,
  }) {
    return Profile(
      id: id,
      name: name,
      age: age,
      bio: bio,
      imageUrls: imageUrls,
      location: location,
      interests: interests,
      distanceKm: distanceKm,
      audioUrl: audioUrl,
      emotion: emotion,
      voiceQuality: voiceQuality,
      accent: accent,
    );
  }

  // JSON serialization
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 18,
      bio: json['bio'] as String? ?? '',
      imageUrls:
          (json['image_urls'] as List<dynamic>?)
              ?.map((url) => url.toString())
              .toList() ??
          [],
      location: json['location'] as String? ?? '',
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map((interest) => interest.toString())
              .toList() ??
          [],
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      audioUrl: json['audio_url'] as String?,
      emotion: json['emotion'] as String?,
      voiceQuality: json['voice_quality'] as String?,
      accent: json['accent'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'image_urls': imageUrls,
      'location': location,
      'interests': interests,
      'distance_km': distanceKm,
      'audio_url': audioUrl,
      'emotion': emotion,
      'voice_quality': voiceQuality,
      'accent': accent,
    };
  }

  // Create a copy with modified fields
  Profile copyWith({
    String? id,
    String? name,
    int? age,
    String? bio,
    List<String>? imageUrls,
    String? location,
    List<String>? interests,
    double? distanceKm,
    String? audioUrl,
    String? emotion,
    String? voiceQuality,
    String? accent,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      distanceKm: distanceKm ?? this.distanceKm,
      audioUrl: audioUrl ?? this.audioUrl,
      emotion: emotion ?? this.emotion,
      voiceQuality: voiceQuality ?? this.voiceQuality,
      accent: accent ?? this.accent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, age: $age, location: $location)';
  }
}
