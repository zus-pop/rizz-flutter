import 'package:rizz_mobile/models/user_profile.dart';

// Sample data for testing swipe cards
final List<UserProfile> sampleProfiles = [
  UserProfile.sample(
    id: '1',
    name: 'Emma',
    age: 25,
    bio:
        'Love traveling and exploring new places! Always up for an adventure. Coffee enthusiast and dog lover.',
    imageUrls: [
      'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=600&fit=crop',
    ],
    location: 'New York, NY',
    interests: ['Travel', 'Photography', 'Coffee', 'Dogs', 'Hiking'],
    distanceKm: 5.2,
  ),
  UserProfile.sample(
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
  ),
  UserProfile.sample(
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
  ),
  UserProfile.sample(
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
  ),
  UserProfile.sample(
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
  ),
  UserProfile.sample(
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
  ),
  UserProfile.sample(
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
  ),
  UserProfile.sample(
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
  ),
];
