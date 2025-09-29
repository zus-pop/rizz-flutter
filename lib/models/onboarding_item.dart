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
    title: "Tìm Kiếm Qua Giọng Nói",
    subtitle: "Khám Phá Bằng Âm Thanh",
    description:
        "Sử dụng giọng nói để tìm kiếm và kết nối với những người phù hợp. Công nghệ nhận diện giọng nói giúp bạn dễ dàng bắt đầu cuộc trò chuyện.",
    imagePath: "assets/images/onboarding_voice1.png",
  ),
  OnboardingItem(
    title: "Trò Chuyện",
    subtitle: "Giao Tiếp Tự Nhiên",
    description:
        "Trải nghiệm trò chuyện tự nhiên hơn qua tin nhắn chat. Thể hiện cảm xúc và cá tính của bạn qua từng tin nhắn.",
    imagePath: "assets/images/onboarding_voice2.png",
  ),
  OnboardingItem(
    title: "Kết Nối Thật Sự",
    subtitle: "Tạo Dấu Ấn Cá Nhân",
    description:
        "Tạo ấn tượng mạnh mẽ bằng giọng nói của bạn. Xây dựng mối quan hệ chân thành và sâu sắc hơn.",
    imagePath: "assets/images/onboarding_voice3.png",
  ),
];
