// Profile options constants similar to React Native input.tsx
class ProfileOption {
  final String id;
  final String name;
  final String? slug;
  final String? description;

  const ProfileOption({
    required this.id,
    required this.name,
    this.slug,
    this.description,
  });
}

class InterestOption {
  final String id;
  final String name;
  final String iconName;

  const InterestOption({
    required this.id,
    required this.name,
    required this.iconName,
  });
}

// Love Languages
const List<ProfileOption> loveLanguageOptions = [
  ProfileOption(id: 'vietnamese', name: 'Tiếng Việt'),
  ProfileOption(id: 'english', name: 'Tiếng Anh'),
  ProfileOption(id: 'chinese', name: 'Tiếng Trung'),
  ProfileOption(id: 'japanese', name: 'Tiếng Nhật'),
  ProfileOption(id: 'korean', name: 'Tiếng Hàn'),
  ProfileOption(id: 'french', name: 'Tiếng Pháp'),
  ProfileOption(id: 'german', name: 'Tiếng Đức'),
  ProfileOption(id: 'spanish', name: 'Tiếng Tây Ban Nha'),
];
// Zodiac Signs
const List<ProfileOption> zodiacOptions = [
  ProfileOption(id: 'aries', name: 'Bạch Dương'),
  ProfileOption(id: 'taurus', name: 'Kim Ngưu'),
  ProfileOption(id: 'gemini', name: 'Song Tử'),
  ProfileOption(id: 'cancer', name: 'Cự Giải'),
  ProfileOption(id: 'leo', name: 'Sư Tử'),
  ProfileOption(id: 'virgo', name: 'Xử Nữ'),
  ProfileOption(id: 'libra', name: 'Thiên Bình'),
  ProfileOption(id: 'scorpio', name: 'Bọ Cạp'),
  ProfileOption(id: 'sagittarius', name: 'Nhân Mã'),
  ProfileOption(id: 'capricorn', name: 'Ma Kết'),
  ProfileOption(id: 'aquarius', name: 'Bảo Bình'),
  ProfileOption(id: 'pisces', name: 'Song Ngư'),
];

// Universities
const List<ProfileOption> universityOptions = [
  ProfileOption(id: 'fpt', name: 'Đại học FPT'),
  ProfileOption(id: 'hust', name: 'Đại học Bách Khoa Hà Nội'),
  ProfileOption(id: 'hcmut', name: 'Đại học Bách Khoa TP. Hồ Chí Minh'),
  ProfileOption(id: 'ftu', name: 'Đại học Ngoại Thương'),
  ProfileOption(id: 'neu', name: 'Đại học Kinh tế Quốc dân'),
  ProfileOption(id: 'ueh', name: 'Đại học Kinh tế TP. Hồ Chí Minh'),
  ProfileOption(id: 'hanu', name: 'Đại học Hà Nội'),
  ProfileOption(id: 'hcmus', name: 'Đại học Khoa học Tự nhiên, ĐHQG-HCM'),
  ProfileOption(id: 'uel', name: 'Đại học Kinh tế - Luật, ĐHQG-HCM'),
  ProfileOption(id: 'other', name: 'Trường của tôi không có trong danh sách'),
];

// Interests with icon names for Flutter Icons
const List<InterestOption> interests = [
  InterestOption(id: 'photography', name: 'Nhiếp ảnh', iconName: 'camera'),
  InterestOption(id: 'shopping', name: 'Mua sắm', iconName: 'shopping_bag'),
  InterestOption(id: 'karaoke', name: 'Karaoke', iconName: 'mic'),
  InterestOption(id: 'yoga', name: 'Yoga', iconName: 'self_improvement'),
  InterestOption(id: 'cooking', name: 'Nấu ăn', iconName: 'restaurant'),
  InterestOption(id: 'tennis', name: 'Quần vợt', iconName: 'sports_tennis'),
  InterestOption(id: 'run', name: 'Chạy bộ', iconName: 'directions_run'),
  InterestOption(id: 'swimming', name: 'Bơi lội', iconName: 'pool'),
  InterestOption(id: 'art', name: 'Nghệ thuật', iconName: 'palette'),
  InterestOption(id: 'traveling', name: 'Du lịch', iconName: 'flight'),
  InterestOption(
    id: 'extreme',
    name: 'Thể thao mạo hiểm',
    iconName: 'paragliding',
  ),
  InterestOption(id: 'music', name: 'Âm nhạc', iconName: 'music_note'),
  InterestOption(id: 'drink', name: 'Đồ uống', iconName: 'local_bar'),
  InterestOption(
    id: 'video-games',
    name: 'Trò chơi điện tử',
    iconName: 'sports_esports',
  ),
];

// Looking For Options
const List<ProfileOption> lookingForOptions = [
  ProfileOption(id: 'long-term-relationship', name: 'Mối quan hệ lâu dài'),
  ProfileOption(id: 'new-friends', name: 'Kết bạn mới'),
  ProfileOption(id: 'something-casual', name: 'Hẹn hò vui vẻ'),
  ProfileOption(id: 'not-sure-yet', name: 'Chưa chắc chắn'),
];

// After Graduation Plans
const List<ProfileOption> afterGraduation = [
  ProfileOption(
    id: 'grad-school-bound',
    name: 'Học tiếp cao học',
    slug: 'grad-school-bound',
  ),
  ProfileOption(
    id: 'career-focused',
    name: 'Tập trung phát triển sự nghiệp',
    slug: 'career-focused',
  ),
  ProfileOption(
    id: 'travel-the-world',
    name: 'Đi du lịch vòng quanh thế giới',
    slug: 'travel-the-world',
  ),
  ProfileOption(
    id: 'start-a-business',
    name: 'Khởi nghiệp kinh doanh',
    slug: 'start-a-business',
  ),
  ProfileOption(
    id: 'still-figuring-it-out',
    name: 'Vẫn đang suy nghĩ',
    slug: 'still-figuring-it-out',
  ),
];

// Campus Life
const List<ProfileOption> campusLife = [
  ProfileOption(id: 'greek-life-member', name: 'Thành viên hội nhóm'),
  ProfileOption(id: 'club-president', name: 'Chủ nhiệm câu lạc bộ'),
  ProfileOption(id: 'sports-team', name: 'Thành viên đội thể thao'),
  ProfileOption(id: 'academic-societies', name: 'Thành viên hội học thuật'),
  ProfileOption(id: 'not-involved', name: 'Không tham gia hoạt động'),
  ProfileOption(id: 'student-leader', name: 'Lãnh đạo sinh viên'),
];

// Deal Breakers
const List<ProfileOption> dealBreakers = [
  ProfileOption(id: 'smoking', name: 'Hút thuốc'),
  ProfileOption(
    id: 'different-political-views',
    name: 'Khác quan điểm chính trị',
  ),
  ProfileOption(id: 'no-ambition', name: 'Thiếu tham vọng'),
  ProfileOption(id: 'heavy-drinking', name: 'Uống rượu nhiều'),
  ProfileOption(id: 'poor-hygiene', name: 'Vệ sinh cá nhân kém'),
  ProfileOption(id: 'dishonesty', name: 'Không trung thực'),
];

// Gender Options
const List<ProfileOption> genderOptions = [
  ProfileOption(id: 'male', name: 'Nam'),
  ProfileOption(id: 'female', name: 'Nữ'),
];

// Communication Preferences
const List<ProfileOption> communicationPreferences = [
  ProfileOption(
    id: 'text-throughout-day',
    name: 'Nhắn tin cả ngày',
    description: 'Tôi thích giữ liên lạc bằng những tin nhắn thường xuyên',
  ),
  ProfileOption(
    id: 'long-phone-calls',
    name: 'Gọi điện thoại lâu',
    description: 'Những cuộc trò chuyện sâu qua điện thoại là sở thích của tôi',
  ),
  ProfileOption(
    id: 'video-chats',
    name: 'Gọi video',
    description: 'Kết nối mặt đối mặt dù ở xa',
  ),
  ProfileOption(
    id: 'in-person-hangouts',
    name: 'Gặp mặt trực tiếp',
    description: 'Không gì tuyệt hơn việc dành thời gian bên nhau ngoài đời',
  ),
];

// Study Styles
const List<ProfileOption> studyStyles = [
  ProfileOption(
    id: 'library-warrior',
    name: 'Chiến binh thư viện',
    description: 'Cắm mặt vào sách, im lặng như ninja!',
  ),
  ProfileOption(
    id: 'coffee-shop-studier',
    name: 'Học ở quán cà phê',
    description: 'Cà phê, tiếng ồn, và mình là học bá!',
  ),
  ProfileOption(
    id: 'dorm-room-hermit',
    name: 'Ẩn sĩ phòng ký túc',
    description: 'Phòng mình, thế giới mình, học kiểu gì cũng được!',
  ),
  ProfileOption(
    id: 'study-group-leader',
    name: 'Trưởng nhóm học tập',
    description: 'Cứ phải có team mới chịu học!',
  ),
];

// Thói quen cuối tuần
const List<ProfileOption> weekendHabits = [
  ProfileOption(id: 'netflix-and-chill', name: 'Netflix and chill'),
  ProfileOption(id: 'party-hard', name: 'Quẩy hết mình'),
  ProfileOption(id: 'explore-the-city', name: 'Khám phá thành phố'),
  ProfileOption(id: 'catch-up-on-sleep', name: 'Ngủ bù'),
];
