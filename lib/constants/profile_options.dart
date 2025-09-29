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
  ProfileOption(
    id: 'words_of_affirmation',
    name: 'Words of Affirmation',
    description:
        'Feeling loved through verbal acknowledgments and encouragement',
  ),
  ProfileOption(
    id: 'acts_of_service',
    name: 'Acts of Service',
    description: 'Feeling loved when others do helpful things for you',
  ),
  ProfileOption(
    id: 'receiving_gifts',
    name: 'Receiving Gifts',
    description: 'Feeling loved through thoughtful gifts and symbols of love',
  ),
  ProfileOption(
    id: 'quality_time',
    name: 'Quality Time',
    description:
        'Feeling loved through undivided attention and meaningful time together',
  ),
  ProfileOption(
    id: 'physical_touch',
    name: 'Physical Touch',
    description:
        'Feeling loved through appropriate physical affection and closeness',
  ),
];

// Zodiac Signs
const List<ProfileOption> zodiacOptions = [
  ProfileOption(id: 'aries', name: 'Aries'),
  ProfileOption(id: 'taurus', name: 'Taurus'),
  ProfileOption(id: 'gemini', name: 'Gemini'),
  ProfileOption(id: 'cancer', name: 'Cancer'),
  ProfileOption(id: 'leo', name: 'Leo'),
  ProfileOption(id: 'virgo', name: 'Virgo'),
  ProfileOption(id: 'libra', name: 'Libra'),
  ProfileOption(id: 'scorpio', name: 'Scorpio'),
  ProfileOption(id: 'sagittarius', name: 'Sagittarius'),
  ProfileOption(id: 'capricorn', name: 'Capricorn'),
  ProfileOption(id: 'aquarius', name: 'Aquarius'),
  ProfileOption(id: 'pisces', name: 'Pisces'),
];

// Universities
const List<ProfileOption> universityOptions = [
  ProfileOption(id: 'fpt', name: 'FPT University'),
  ProfileOption(id: 'vnu-hanoi', name: 'Vietnam National University, Hanoi'),
  ProfileOption(
    id: 'vnu-hcmc',
    name: 'Vietnam National University, Ho Chi Minh City',
  ),
  ProfileOption(id: 'hust', name: 'Hanoi University of Science and Technology'),
  ProfileOption(id: 'hcmut', name: 'Ho Chi Minh City University of Technology'),
  ProfileOption(id: 'ftu', name: 'Foreign Trade University'),
  ProfileOption(id: 'neu', name: 'National Economics University'),
  ProfileOption(id: 'ueh', name: 'University of Economics Ho Chi Minh City'),
  ProfileOption(id: 'hanu', name: 'Hanoi University'),
  ProfileOption(id: 'hcmus', name: 'University of Science, VNU-HCM'),
  ProfileOption(id: 'uel', name: 'University of Economics and Law, VNU-HCM'),
];

// Interests with icon names for Flutter Icons
const List<InterestOption> interests = [
  InterestOption(id: 'photography', name: 'Photography', iconName: 'camera'),
  InterestOption(id: 'shopping', name: 'Shopping', iconName: 'shopping_bag'),
  InterestOption(id: 'karaoke', name: 'Karaoke', iconName: 'mic'),
  InterestOption(id: 'yoga', name: 'Yoga', iconName: 'self_improvement'),
  InterestOption(id: 'cooking', name: 'Cooking', iconName: 'restaurant'),
  InterestOption(id: 'tennis', name: 'Tennis', iconName: 'sports_tennis'),
  InterestOption(id: 'run', name: 'Run', iconName: 'directions_run'),
  InterestOption(id: 'swimming', name: 'Swimming', iconName: 'pool'),
  InterestOption(id: 'art', name: 'Art', iconName: 'palette'),
  InterestOption(id: 'traveling', name: 'Traveling', iconName: 'flight'),
  InterestOption(id: 'extreme', name: 'Extreme', iconName: 'paragliding'),
  InterestOption(id: 'music', name: 'Music', iconName: 'music_note'),
  InterestOption(id: 'drink', name: 'Drink', iconName: 'local_bar'),
  InterestOption(
    id: 'video-games',
    name: 'Video games',
    iconName: 'sports_esports',
  ),
];

// Looking For Options
const List<ProfileOption> lookingForOptions = [
  ProfileOption(id: 'long-term-relationship', name: 'Long-term relationship'),
  ProfileOption(id: 'new-friends', name: 'New friends'),
  ProfileOption(id: 'something-casual', name: 'Something casual'),
  ProfileOption(id: 'not-sure-yet', name: 'Not sure yet'),
];

// After Graduation Plans
const List<ProfileOption> afterGraduation = [
  ProfileOption(
    id: 'grad-school-bound',
    name: 'Grad school bound',
    slug: 'grad-school-bound',
  ),
  ProfileOption(
    id: 'career-focused',
    name: 'Career focused',
    slug: 'career-focused',
  ),
  ProfileOption(
    id: 'travel-the-world',
    name: 'Travel the world',
    slug: 'travel-the-world',
  ),
  ProfileOption(
    id: 'start-a-business',
    name: 'Start a business',
    slug: 'start-a-business',
  ),
  ProfileOption(
    id: 'still-figuring-it-out',
    name: 'Still figuring it out',
    slug: 'still-figuring-it-out',
  ),
];

// Campus Life
const List<ProfileOption> campusLife = [
  ProfileOption(id: 'greek-life-member', name: 'Greek life member'),
  ProfileOption(id: 'club-president', name: 'Club president'),
  ProfileOption(id: 'sports-team', name: 'Sports team'),
  ProfileOption(id: 'academic-societies', name: 'Academic societies'),
  ProfileOption(id: 'not-involved', name: 'Not involved'),
  ProfileOption(id: 'student-leader', name: 'Student leader'),
];

// Deal Breakers
const List<ProfileOption> dealBreakers = [
  ProfileOption(id: 'smoking', name: 'Smoking'),
  ProfileOption(
    id: 'different-political-views',
    name: 'Different political views',
  ),
  ProfileOption(id: 'no-ambition', name: 'No ambition'),
  ProfileOption(id: 'heavy-drinking', name: 'Heavy drinking'),
  ProfileOption(id: 'poor-hygiene', name: 'Poor hygiene'),
  ProfileOption(id: 'dishonesty', name: 'Dishonesty'),
];

// Gender Options
const List<ProfileOption> genderOptions = [
  ProfileOption(id: 'female', name: 'Female'),
  ProfileOption(id: 'male', name: 'Male'),
];

// Communication Preferences
// Communication Preferences
const List<ProfileOption> communicationPreferences = [
  ProfileOption(
    id: 'text-throughout-day',
    name: 'Text throughout the day',
    description: 'I love staying connected with frequent messages',
  ),
  ProfileOption(
    id: 'long-phone-calls',
    name: 'Long phone calls',
    description: 'Deep conversations over the phone are my thing',
  ),
  ProfileOption(
    id: 'video-chats',
    name: 'Video chats',
    description: 'Face-to-face connection, even when apart',
  ),
  ProfileOption(
    id: 'in-person-hangouts',
    name: 'In-person hangouts',
    description: 'Nothing beats spending time together in person',
  ),
];

// Study Styles
const List<ProfileOption> studyStyles = [
  ProfileOption(
    id: 'library-warrior',
    name: 'Library warrior',
    description: 'Dead silence and stacks of books - that\'s my zone',
  ),
  ProfileOption(
    id: 'coffee-shop-studier',
    name: 'Coffee shop studier',
    description: 'Background noise and caffeine fuel my focus',
  ),
  ProfileOption(
    id: 'dorm-room-hermit',
    name: 'Dorm room hermit',
    description: 'My room, my rules, my perfect study environment',
  ),
  ProfileOption(
    id: 'study-group-leader',
    name: 'Study group leader',
    description: 'Learning is better when we\'re all in it together',
  ),
];

// Weekend Habits
const List<ProfileOption> weekendHabits = [
  ProfileOption(id: 'netflix-and-chill', name: 'Netflix and chill'),
  ProfileOption(id: 'party-hard', name: 'Party hard'),
  ProfileOption(id: 'explore-the-city', name: 'Explore the city'),
  ProfileOption(id: 'catch-up-on-sleep', name: 'Catch up on sleep'),
];
