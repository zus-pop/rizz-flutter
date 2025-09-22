# User Profile Service & Provider Setup

This documentation explains how to use the User Profile Service and Provider for API integration with pagination.

## Overview

The setup includes:

- **UserProfileService**: Handles HTTP API calls
- **UserProfileProvider**: Manages state using Provider pattern
- **Pagination**: Automatically loads more profiles as needed
- **Filtering**: Age range and distance filtering
- **Error Handling**: Proper error states and retry functionality

## Files Created

1. `lib/services/profile_service.dart` - API service layer
2. `lib/providers/profile_provider.dart` - State management
3. Updated `lib/models/profile.dart` - Added JSON serialization
4. Updated `lib/main.dart` - Provider setup
5. Updated `lib/pages/tabs/discover.dart` - Consumer integration

## Configuration

### 1. Switch to Real API

In `lib/providers/profile_provider.dart`, change:

```dart
bool _useSampleData = true; // Set to false when you have a real API
```

### 2. Update API URL

In `lib/services/profile_service.dart`, update:

```dart
static const String baseUrl = 'https://your-api.com'; // Replace with your actual API URL
```

### 3. Add Authentication

If your API requires authentication, update the headers in the service:

```dart
final response = await http.get(
  uri,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $your_token', // Add your auth token
  },
);
```

## Expected API Response Format

The service expects your API to return paginated responses in this format:

```json
{
  "data": [
    {
      "id": "1",
      "name": "Emma",
      "age": 25,
      "bio": "Love traveling...",
      "image_urls": ["https://example.com/image1.jpg"],
      "location": "New York, NY",
      "interests": ["Travel", "Photography"],
      "distance_km": 5.2,
      "audio_url": "https://example.com/audio.mp3"
    }
  ],
  "current_page": 1,
  "total_pages": 10,
  "total": 95,
  "has_next_page": true,
  "has_previous_page": false
}
```

## API Endpoints

The service expects these endpoints:

- `GET /profiles` - Get paginated profiles with filters
- `GET /profiles/{id}` - Get single profile
- `POST /profiles/{id}/like` - Like a profile
- `POST /profiles/{id}/pass` - Pass a profile

### Query Parameters for `/profiles`:

- `page` - Page number (starts from 1)
- `limit` - Number of profiles per page
- `age_min` - Minimum age filter
- `age_max` - Maximum age filter
- `max_distance` - Maximum distance in kilometers

## Usage in Widgets

### Consumer Pattern

```dart
Consumer<UserProfileProvider>(
  builder: (context, profileProvider, child) {
    if (profileProvider.isLoading) {
      return CircularProgressIndicator();
    }

    if (profileProvider.hasError) {
      return Text('Error: ${profileProvider.errorMessage}');
    }

    return ListView.builder(
      itemCount: profileProvider.profiles.length,
      itemBuilder: (context, index) {
        return ProfileCard(profile: profileProvider.profiles[index]);
      },
    );
  },
)
```

### Manual Actions

```dart
// Load profiles
await context.read<UserProfileProvider>().loadProfiles(refresh: true);

// Apply filters
await context.read<UserProfileProvider>().applyFilters(
  ageRange: RangeValues(20, 30),
  maxDistance: 50.0,
);

// Like/Pass profiles
await context.read<UserProfileProvider>().likeProfile('profile_id');
await context.read<UserProfileProvider>().passProfile('profile_id');

// Load more (pagination)
await context.read<UserProfileProvider>().loadMoreProfiles();
```

## Features

### ✅ Automatic Pagination

- Loads more profiles as user swipes
- Configurable page size
- Loading indicators for "load more" state

### ✅ Filtering

- Age range slider (18-65)
- Distance radius slider (1-100km)
- Real-time filter application

### ✅ Error Handling

- Network error recovery
- Retry functionality
- User-friendly error messages

### ✅ State Management

- Loading states (idle, loading, loadingMore, success, error)
- Automatic state updates
- Provider pattern for reactive UI

### ✅ Performance

- Efficient pagination
- Profile removal after swipe actions
- Memory-conscious image loading

## Development Mode

Currently using sample data for development. The provider automatically:

- Uses local sample profiles
- Simulates API delays
- Applies filters to sample data
- Handles like/pass actions locally

## Production Checklist

Before deploying:

1. ✅ Set `_useSampleData = false` in UserProfileProvider
2. ✅ Update `baseUrl` in UserProfileService
3. ✅ Add proper authentication headers
4. ✅ Test API endpoints match expected format
5. ✅ Configure error handling for your API
6. ✅ Test pagination with real data
7. ✅ Verify image URLs are accessible
8. ✅ Test audio URLs if using voice features

## Error Handling

The system handles common errors:

- Network connectivity issues
- API server errors (4xx, 5xx)
- Malformed JSON responses
- Missing profile data
- Image loading failures

Users see appropriate error messages and can retry failed operations.
