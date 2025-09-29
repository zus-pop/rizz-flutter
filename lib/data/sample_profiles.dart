import 'package:rizz_mobile/models/profile.dart';

// Sample audio URLs to cycle through
final List<String> audioSamples = [
  'https://software-mansion.github.io/react-native-audio-api/audio/music/example-music-01.mp3',
  'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
  'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
];

final List<Profile> sampleProfiles = [
  Profile.sample(
    id: '1',
    name: 'Emma',
    age: 25,
    bio:
        'Love traveling and exploring new places! Always up for an adventure. Coffee enthusiast and dog lover.',
    imageUrls: [
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=600&fit=crop',
    ],
    location: 'New York, NY',
    interests: ['Travel', 'Photography', 'Coffee', 'Dogs', 'Hiking'],
    distanceKm: 5.2,
    audioUrl: audioSamples[0],
    emotion: 'Vui',
    voiceQuality: 'Sáng',
    accent: 'Đông Nam Bộ',
  ),
  Profile.sample(
    id: '2',
    name: 'Sophia',
    age: 28,
    bio:
        'Yoga instructor and mindfulness coach. Looking for someone who shares my passion for wellness and personal growth.',
    imageUrls: [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=600&fit=crop',
    ],
    location: 'Los Angeles, CA',
    interests: ['Yoga', 'Meditation', 'Healthy Living', 'Books', 'Nature'],
    distanceKm: 12.8,
    audioUrl: audioSamples[1],
    emotion: 'Trung lập',
    voiceQuality: 'Mượt',
    accent: 'Tây Nguyên',
  ),
  Profile.sample(
    id: '3',
    name: 'Isabella',
    age: 24,
    bio:
        'Artist and creative soul. I paint, dance, and live life in full color. Looking for someone to share beautiful moments with.',
    imageUrls: [
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&h=600&fit=crop',
    ],
    location: 'San Francisco, CA',
    interests: ['Art', 'Dancing', 'Music', 'Creativity', 'Museums'],
    distanceKm: 25.7,
    audioUrl: audioSamples[2],
    emotion: 'Tự tin',
    voiceQuality: 'Trong',
    accent: 'Bắc Trung Bộ',
  ),
  Profile.sample(
    id: '4',
    name: 'Olivia',
    age: 26,
    bio:
        'Tech enthusiast by day, foodie by night. I love trying new restaurants and cooking exotic dishes.',
    imageUrls: [
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=600&fit=crop',
    ],
    location: 'Seattle, WA',
    interests: ['Technology', 'Cooking', 'Food', 'Innovation', 'Gaming'],
    distanceKm: 38.4,
    audioUrl: audioSamples[0],
    emotion: 'Buồn',
    voiceQuality: 'Khàn',
    accent: 'Đồng bằng sông Hồng',
  ),
  Profile.sample(
    id: '5',
    name: 'Ava',
    age: 23,
    bio:
        'Fitness enthusiast and outdoor adventurer. Life is too short to stay indoors! Let\'s explore together.',
    imageUrls: [
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=600&fit=crop',
    ],
    location: 'Denver, CO',
    interests: [
      'Fitness',
      'Rock Climbing',
      'Skiing',
      'Running',
      'Outdoor Sports',
    ],
    distanceKm: 52.3,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '6',
    name: 'Mia',
    age: 27,
    bio:
        'Book lover and aspiring writer. I believe every person has a story worth telling. What\'s yours?',
    imageUrls: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=600&fit=crop',
    ],
    location: 'Boston, MA',
    interests: ['Reading', 'Writing', 'Literature', 'Poetry', 'Libraries'],
    distanceKm: 19.6,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '7',
    name: 'Charlotte',
    age: 29,
    bio:
        'Marine biologist with a passion for ocean conservation. Let\'s dive deep into meaningful conversations!',
    imageUrls: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop',
    ],
    location: 'Miami, FL',
    interests: ['Marine Biology', 'Diving', 'Conservation', 'Science', 'Ocean'],
    distanceKm: 67.1,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '8',
    name: 'Amelia',
    age: 25,
    bio:
        'Musician and music teacher. Life without music is like a day without sunshine. Let\'s make beautiful music together!',
    imageUrls: [
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=600&fit=crop',
    ],
    location: 'Nashville, TN',
    interests: ['Music', 'Guitar', 'Singing', 'Teaching', 'Concerts'],
    distanceKm: 33.9,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '9',
    name: 'Harper',
    age: 30,
    bio:
        'Marketing executive with a love for weekend hiking. Work hard, play harder! Looking for someone to share adventures with.',
    imageUrls: [
      'https://images.unsplash.com/photo-1494790108755-2616b612b372?w=400&h=600&fit=crop',
    ],
    location: 'Austin, TX',
    interests: ['Marketing', 'Hiking', 'Wine Tasting', 'Photography', 'Travel'],
    distanceKm: 8.7,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '10',
    name: 'Lily',
    age: 22,
    bio:
        'Psychology student and part-time barista. I love deep conversations over coffee and analyzing what makes people tick.',
    imageUrls: [
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=600&fit=crop',
    ],
    location: 'Portland, OR',
    interests: [
      'Psychology',
      'Coffee',
      'Books',
      'Art Therapy',
      'Volunteer Work',
    ],
    distanceKm: 15.3,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '11',
    name: 'Grace',
    age: 26,
    bio:
        'Veterinarian who spends weekends rescuing animals. If you love pets as much as I do, we\'ll get along great!',
    imageUrls: [
      'https://images.unsplash.com/photo-1488716820095-cbe80883c496?w=400&h=600&fit=crop',
    ],
    location: 'San Diego, CA',
    interests: [
      'Veterinary Medicine',
      'Animal Rescue',
      'Beach Walks',
      'Surfing',
      'Conservation',
    ],
    distanceKm: 42.1,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '12',
    name: 'Zoe',
    age: 24,
    bio:
        'Fashion designer with dreams of starting my own sustainable clothing line. Style meets sustainability!',
    imageUrls: [
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=600&fit=crop',
    ],
    location: 'Chicago, IL',
    interests: [
      'Fashion Design',
      'Sustainability',
      'Art',
      'Vintage Shopping',
      'Sewing',
    ],
    distanceKm: 29.8,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '13',
    name: 'Chloe',
    age: 27,
    bio:
        'Nutritionist and personal trainer. Helping others achieve their health goals is my passion. Let\'s get fit together!',
    imageUrls: [
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=600&fit=crop',
    ],
    location: 'Phoenix, AZ',
    interests: [
      'Nutrition',
      'Personal Training',
      'Meal Prep',
      'Yoga',
      'Wellness',
    ],
    distanceKm: 61.4,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '14',
    name: 'Madison',
    age: 23,
    bio:
        'Social media manager who loves creating content. When I\'m not working, you\'ll find me exploring new cafes and vintage shops.',
    imageUrls: [
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&h=600&fit=crop',
    ],
    location: 'Atlanta, GA',
    interests: [
      'Social Media',
      'Content Creation',
      'Photography',
      'Vintage Fashion',
      'Coffee',
    ],
    distanceKm: 18.9,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '15',
    name: 'Aria',
    age: 25,
    bio:
        'Professional dancer turned dance instructor. Life is a dance floor, and I\'m looking for a partner to share it with!',
    imageUrls: [
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400&h=600&fit=crop',
    ],
    location: 'Las Vegas, NV',
    interests: ['Dancing', 'Choreography', 'Teaching', 'Performance', 'Music'],
    distanceKm: 73.2,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '16',
    name: 'Nora',
    age: 28,
    bio:
        'Software engineer by day, gamer by night. I code in multiple languages and speak fluent sarcasm. Ready player two?',
    imageUrls: [
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=600&fit=crop',
    ],
    location: 'San Francisco, CA',
    interests: ['Programming', 'Gaming', 'Tech', 'Board Games', 'Anime'],
    distanceKm: 11.6,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '17',
    name: 'Luna',
    age: 26,
    bio:
        'Astronomy PhD candidate who loves stargazing. The universe is vast and full of mysteries - want to explore it together?',
    imageUrls: [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=600&fit=crop',
    ],
    location: 'Boulder, CO',
    interests: ['Astronomy', 'Stargazing', 'Research', 'Physics', 'Nature'],
    distanceKm: 45.7,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '18',
    name: 'Penelope',
    age: 24,
    bio:
        'Event planner who turns dreams into reality. I love organizing magical moments and creating unforgettable experiences.',
    imageUrls: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop',
    ],
    location: 'New Orleans, LA',
    interests: [
      'Event Planning',
      'Party Design',
      'Decoration',
      'Music',
      'Celebrating',
    ],
    distanceKm: 36.3,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '19',
    name: 'Scarlett',
    age: 29,
    bio:
        'Wine sommelier and food blogger. I believe life is too short for bad wine and boring conversations. Cheers to new adventures!',
    imageUrls: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=600&fit=crop',
    ],
    location: 'Napa Valley, CA',
    interests: [
      'Wine Tasting',
      'Food Blogging',
      'Culinary Arts',
      'Travel',
      'Fine Dining',
    ],
    distanceKm: 89.1,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '20',
    name: 'Ruby',
    age: 23,
    bio:
        'Graphic designer with a passion for minimalist aesthetics. I see beauty in simplicity and love creating clean, impactful designs.',
    imageUrls: [
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=600&fit=crop',
    ],
    location: 'Brooklyn, NY',
    interests: [
      'Graphic Design',
      'Art',
      'Typography',
      'Minimalism',
      'Creative Direction',
    ],
    distanceKm: 7.4,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '21',
    name: 'Violet',
    age: 27,
    bio:
        'Environmental scientist fighting climate change one project at a time. Passionate about sustainability and green living.',
    imageUrls: [
      'https://images.unsplash.com/photo-1494790108755-2616b612b372?w=400&h=600&fit=crop',
    ],
    location: 'Seattle, WA',
    interests: [
      'Environmental Science',
      'Sustainability',
      'Climate Action',
      'Hiking',
      'Research',
    ],
    distanceKm: 54.8,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '22',
    name: 'Hazel',
    age: 25,
    bio:
        'Professional photographer capturing life\'s precious moments. Always looking for the perfect light and the perfect shot.',
    imageUrls: [
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=600&fit=crop',
    ],
    location: 'Santa Fe, NM',
    interests: [
      'Photography',
      'Art',
      'Travel',
      'Nature',
      'Visual Storytelling',
    ],
    distanceKm: 67.9,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '23',
    name: 'Stella',
    age: 26,
    bio:
        'Interior designer who loves creating beautiful, functional spaces. Home is where the heart is, and I design from the heart.',
    imageUrls: [
      'https://images.unsplash.com/photo-1488716820095-cbe80883c496?w=400&h=600&fit=crop',
    ],
    location: 'Charleston, SC',
    interests: [
      'Interior Design',
      'Home Decor',
      'Architecture',
      'Art',
      'Antiques',
    ],
    distanceKm: 41.2,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '24',
    name: 'Iris',
    age: 28,
    bio:
        'Meditation instructor and wellness coach. Finding peace in chaos and helping others do the same. Namaste.',
    imageUrls: [
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=600&fit=crop',
    ],
    location: 'Sedona, AZ',
    interests: [
      'Meditation',
      'Wellness',
      'Mindfulness',
      'Yoga',
      'Spiritual Growth',
    ],
    distanceKm: 78.3,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '25',
    name: 'Jasmine',
    age: 24,
    bio:
        'Travel blogger documenting adventures around the world. Life is a journey, not a destination. Want to explore together?',
    imageUrls: [
      'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=600&fit=crop',
    ],
    location: 'Miami, FL',
    interests: [
      'Travel',
      'Blogging',
      'Photography',
      'Adventure',
      'Cultural Exploration',
    ],
    distanceKm: 23.7,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '26',
    name: 'Aurora',
    age: 22,
    bio:
        'Film student with dreams of directing the next great indie movie. I see stories everywhere and love bringing them to life.',
    imageUrls: [
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=600&fit=crop',
    ],
    location: 'Los Angeles, CA',
    interests: [
      'Filmmaking',
      'Directing',
      'Screenwriting',
      'Cinema',
      'Storytelling',
    ],
    distanceKm: 14.5,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '27',
    name: 'Sage',
    age: 29,
    bio:
        'Sustainable fashion advocate and vintage clothing curator. Style should never come at the expense of our planet.',
    imageUrls: [
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&h=600&fit=crop',
    ],
    location: 'Portland, OR',
    interests: [
      'Sustainable Fashion',
      'Vintage Clothing',
      'Thrifting',
      'Upcycling',
      'Environmental Advocacy',
    ],
    distanceKm: 52.1,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '28',
    name: 'Maya',
    age: 26,
    bio:
        'Yoga teacher and wellness retreat leader. Finding balance in all aspects of life and helping others do the same.',
    imageUrls: [
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400&h=600&fit=crop',
    ],
    location: 'Tulum, Mexico',
    interests: [
      'Yoga',
      'Wellness Retreats',
      'Meditation',
      'Healthy Living',
      'Travel',
    ],
    distanceKm: 95.6,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '29',
    name: 'Willow',
    age: 25,
    bio:
        'Marine conservation photographer. Diving deep to capture the beauty of our oceans and protect them for future generations.',
    imageUrls: [
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=600&fit=crop',
    ],
    location: 'Key West, FL',
    interests: [
      'Marine Photography',
      'Conservation',
      'Scuba Diving',
      'Ocean Protection',
      'Wildlife',
    ],
    distanceKm: 84.7,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '30',
    name: 'Ivy',
    age: 27,
    bio:
        'Botanical illustrator and garden designer. I believe in the healing power of nature and love creating green spaces.',
    imageUrls: [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=600&fit=crop',
    ],
    location: 'Asheville, NC',
    interests: [
      'Botanical Art',
      'Garden Design',
      'Plant Care',
      'Nature',
      'Illustration',
    ],
    distanceKm: 38.9,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '31',
    name: 'Phoenix',
    age: 24,
    bio:
        'Renewable energy engineer working towards a sustainable future. Innovation and environmental responsibility go hand in hand.',
    imageUrls: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop',
    ],
    location: 'Denver, CO',
    interests: [
      'Renewable Energy',
      'Engineering',
      'Innovation',
      'Sustainability',
      'Technology',
    ],
    distanceKm: 46.3,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '32',
    name: 'River',
    age: 28,
    bio:
        'Adventure guide and wilderness survival instructor. Life begins at the end of your comfort zone. Ready for an adventure?',
    imageUrls: [
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=600&fit=crop',
    ],
    location: 'Jackson Hole, WY',
    interests: [
      'Adventure Guiding',
      'Wilderness Survival',
      'Rock Climbing',
      'Backpacking',
      'Outdoor Education',
    ],
    distanceKm: 71.8,
    audioUrl: audioSamples[1],
  ),
  Profile.sample(
    id: '33',
    name: 'Skye',
    age: 23,
    bio:
        'Meteorologist and storm chaser. I love understanding weather patterns and the power of nature. Every day brings new discoveries.',
    imageUrls: [
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=600&fit=crop',
    ],
    location: 'Norman, OK',
    interests: [
      'Meteorology',
      'Storm Chasing',
      'Weather Research',
      'Science',
      'Nature Photography',
    ],
    distanceKm: 63.4,
    audioUrl: audioSamples[2],
  ),
  Profile.sample(
    id: '34',
    name: 'Eden',
    age: 26,
    bio:
        'Organic farmer and farm-to-table chef. Growing my own ingredients and creating delicious, healthy meals from the earth.',
    imageUrls: [
      'https://images.unsplash.com/photo-1494790108755-2616b612b372?w=400&h=600&fit=crop',
    ],
    location: 'Sonoma County, CA',
    interests: [
      'Organic Farming',
      'Farm-to-Table Cooking',
      'Sustainable Agriculture',
      'Healthy Eating',
      'Gardening',
    ],
    distanceKm: 56.7,
    audioUrl: audioSamples[0],
  ),
  Profile.sample(
    id: '35',
    name: 'Nova',
    age: 25,
    bio:
        'Space technology engineer working on the next generation of satellites. The future is written in the stars, literally!',
    imageUrls: [
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=600&fit=crop',
    ],
    location: 'Houston, TX',
    interests: [
      'Space Technology',
      'Engineering',
      'Astronomy',
      'Innovation',
      'Science Fiction',
    ],
    distanceKm: 31.2,
    audioUrl: audioSamples[1],
  ),
];
