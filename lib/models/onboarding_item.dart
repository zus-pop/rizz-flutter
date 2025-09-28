class OnboardingItem {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;

  OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
  });
}

final List<OnboardingItem> onboardingItems = [
  OnboardingItem(
    title: "Find Your Perfect Match",
    subtitle: "Discover Love",
    description: "Connect with people who share your interests and values. Our smart matching algorithm helps you find meaningful relationships.",
    imagePath: "assets/images/onboarding1.png",
  ),
  OnboardingItem(
    title: "Chat & Connect",
    subtitle: "Start Conversations",
    description: "Break the ice with engaging conversations. Share your thoughts, experiences, and build genuine connections.",
    imagePath: "assets/images/onboarding2.png",
  ),
  OnboardingItem(
    title: "Meet in Person",
    subtitle: "Take It Further",
    description: "When you're ready, plan real dates and meet in person. Turn your online connections into lasting relationships.",
    imagePath: "assets/images/onboarding3.png",
  ),
];