class UserProfile {
  final String id;
  final String name;
  final int age;
  final String bio;
  final List<String> imageUrls;
  final String location;
  final List<String> interests;
  final double distanceKm; // Distance in kilometers

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.bio,
    required this.imageUrls,
    required this.location,
    required this.interests,
    required this.distanceKm,
  });

  // Create a sample user profile
  factory UserProfile.sample({
    required String id,
    required String name,
    required int age,
    required String bio,
    required List<String> imageUrls,
    required String location,
    required List<String> interests,
    required double distanceKm,
  }) {
    return UserProfile(
      id: id,
      name: name,
      age: age,
      bio: bio,
      imageUrls: imageUrls,
      location: location,
      interests: interests,
      distanceKm: distanceKm,
    );
  }
}
