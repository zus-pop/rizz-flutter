import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/providers/auth_provider.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/widgets/filter_modal.dart';
import 'package:rizz_mobile/widgets/swipe_card.dart';

class Discover extends StatefulWidget {
  const Discover({super.key});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    // final state = context.read<AuthProvider>().authState;
    // if (state == AuthState.authenticated) {
    context.read<AuthProvider>().updateToken();
    // }
    // Initialize profiles when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().initialize();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(
        255,
        234,
        229,
        255,
      ), // Secondary color background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            // Add your left icon action here
            // For example: open drawer, go back, etc.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Left icon pressed!'),
                backgroundColor: Color(0xFFfa5eff),
                duration: Duration(milliseconds: 1000),
              ),
            );
          },
          icon: Icon(Icons.gamepad, color: Color(0xFFfa5eff), size: 30),
        ),
        title: Text(
          'Discover',
          style: TextStyle(
            color: Color(0xFFfa5eff),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true, // This ensures the title stays centered
        actions: [
          IconButton(
            onPressed: _showFilterModal,
            icon: Icon(Icons.tune, color: Color(0xFFfa5eff), size: 30),
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          debugPrint(profileProvider.profiles.length.toString());
          // Handle different loading states
          if (profileProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFfa5eff)),
                  SizedBox(height: 16),
                  Text(
                    'Loading profiles...',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            );
          }

          if (profileProvider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading profiles',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    profileProvider.errorMessage ?? 'Unknown error',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => profileProvider.retry(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFfa5eff),
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (profileProvider.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No more profiles to show',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Check back later for new matches!',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          // Show profiles with swiper
          return Stack(
            children: [
              // Card swiper - takes full height
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: 120.0, // Space for action buttons
                ),
                child: CardSwiper(
                  controller: controller,
                  cardsCount: profileProvider.profiles.length,
                  isLoop: false,
                  onSwipe: (previousIndex, currentIndex, direction) {
                    _onSwipe(
                      previousIndex,
                      currentIndex,
                      direction,
                      profileProvider,
                    );
                    return true;
                  },
                  onUndo: _onUndo,
                  onEnd: () {
                    debugPrint("end here");
                  },
                  threshold:
                      80, // Lower threshold for easier swiping near phone edges
                  numberOfCardsDisplayed: 2,
                  backCardOffset: const Offset(0, -20),
                  padding: const EdgeInsets.all(8.0),
                  allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
                    horizontal: true,
                    vertical: false,
                  ),
                  cardBuilder:
                      (
                        context,
                        index,
                        horizontalThresholdPercentage,
                        verticalThresholdPercentage,
                      ) {
                        // Safety check for index bounds
                        if (index >= 0 &&
                            index < profileProvider.profiles.length) {
                          return SwipeCard(
                            profile: profileProvider.profiles[index],
                          );
                        } else {
                          // Return empty container if index is out of bounds
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.grey[300],
                            ),
                            child: const Center(
                              child: Text('No profile available'),
                            ),
                          );
                        }
                      },
                ),
              ),

              // Load more indicator
              if (profileProvider.isLoadingMore)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Loading more...',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),

              // Action buttons - positioned absolutely
              Positioned(
                bottom: 80, // Above the bottom navigation
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pass button
                      _buildActionButton(
                        icon: Icons.close,
                        color: Colors.red[400]!,
                        onPressed: () =>
                            controller.swipe(CardSwiperDirection.left),
                        size: 56,
                      ),

                      _buildActionButton(
                        icon: Icons.undo,
                        color: Colors.green[400]!,
                        onPressed: () => controller.undo(),
                        size: 56,
                      ),

                      // Like button
                      _buildActionButton(
                        icon: Icons.favorite,
                        color: Color(0xFFfa5eff),
                        onPressed: () =>
                            controller.swipe(CardSwiperDirection.right),
                        size: 56,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double size,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
    ProfileProvider profileProvider,
  ) {
    currentIndex = currentIndex ?? 0;

    String action = '';
    String profileId = '';
    switch (direction) {
      case CardSwiperDirection.left:
        action = 'passed';
        if (previousIndex >= 0 &&
            previousIndex < profileProvider.profiles.length) {
          profileId = profileProvider.profiles[previousIndex].id;
          profileProvider.passProfile(profileId);
        }
        break;
      case CardSwiperDirection.right:
        action = 'liked';
        if (previousIndex >= 0 &&
            previousIndex < profileProvider.profiles.length) {
          profileId = profileProvider.profiles[previousIndex].id;
          profileProvider.likeProfile(profileId);
        }
        break;
      default:
        action = 'swiped';
    }

    // Show feedback with bounds checking
    if (mounted &&
        previousIndex >= 0 &&
        previousIndex < profileProvider.profiles.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You $action ${profileProvider.profiles[previousIndex].name}!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: direction == CardSwiperDirection.right
              ? Color(0xFFfa5eff)
              : Colors.grey,
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        ),
      );
    }

    if (previousIndex >= 0 && previousIndex < profileProvider.profiles.length) {
      debugPrint(
        'Card ${profileProvider.profiles[previousIndex].name} was $action. Current index: $currentIndex',
      );
    } else {
      debugPrint(
        'Card at index $previousIndex was $action. Current index: $currentIndex',
      );
    }

    // Check if we need to load more profiles
    if (profileProvider.profiles.length - currentIndex <= 2 &&
        profileProvider.hasNextPage) {
      profileProvider.loadMoreProfiles();
    }

    return true;
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    debugPrint('Card $currentIndex was undone from the ${direction.name}');
    return true;
  }

  void _showFilterModal() {
    final profileProvider = context.read<ProfileProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        initialAgeRange: profileProvider.ageRange,
        initialDistance: profileProvider.maxDistance,
        onApplyFilter: (newAgeRange, newMaxDistance) {
          profileProvider.applyFilters(
            ageRange: newAgeRange,
            maxDistance: newMaxDistance,
          );
        },
      ),
    );
  }
}
