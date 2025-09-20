import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:rizz_mobile/models/user_profile.dart';
import 'package:rizz_mobile/widgets/swipe_card.dart';
import 'package:rizz_mobile/widgets/filter_modal.dart';
import 'package:rizz_mobile/data/sample_profiles.dart';

class Discover extends StatefulWidget {
  const Discover({super.key});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover> {
  final CardSwiperController controller = CardSwiperController();
  List<UserProfile> profiles = [];
  List<UserProfile> allProfiles = [];
  int currentIndex = 0;

  // Filter state
  RangeValues ageRange = const RangeValues(18, 65);
  double maxDistance = 100;

  @override
  void initState() {
    super.initState();
    allProfiles = List.from(sampleProfiles);
    _applyFilters();
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
        title: Row(
          children: [
            Icon(Icons.favorite, color: Color(0xFFfa5eff), size: 28),
            const SizedBox(width: 8),
            Text(
              'Discover',
              style: TextStyle(
                color: Color(0xFFfa5eff),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showFilterModal,
            icon: Icon(Icons.tune, color: Color(0xFFfa5eff)),
          ),
        ],
      ),
      body: profiles.isEmpty
          ? const Center(
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
            )
          : Stack(
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
                    cardsCount: profiles.length,
                    onSwipe: _onSwipe,
                    onUndo: _onUndo,
                    numberOfCardsDisplayed: 2,
                    backCardOffset: const Offset(0, -20),
                    padding: const EdgeInsets.all(8.0),
                    allowedSwipeDirection:
                        const AllowedSwipeDirection.symmetric(
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
                          return SwipeCard(profile: profiles[index]);
                        },
                  ),
                ),

                // Action buttons - positioned absolutely
                Positioned(
                  bottom: 70, // Above the bottom navigation
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
                          color: Colors.grey[400]!,
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
        child: Icon(icon, color: color, size: size * 0.4),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    currentIndex = currentIndex ?? 0;

    String action = '';
    switch (direction) {
      case CardSwiperDirection.left:
        action = 'passed';
        break;
      case CardSwiperDirection.right:
        action = 'liked';
        break;
      default:
        action = 'swiped';
    }

    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You $action ${profiles[previousIndex].name}!',
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

    debugPrint(
      'Card ${profiles[previousIndex].name} was $action. Current index: $currentIndex',
    );

    // Remove the swiped profile from the list after a delay to allow animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // profiles.removeAt(previousIndex);
        });
      }
    });

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

  void _applyFilters() {
    setState(() {
      profiles = allProfiles.where((profile) {
        // Age filter
        bool ageMatch =
            profile.age >= ageRange.start && profile.age <= ageRange.end;

        // Distance filter
        bool distanceMatch = profile.distanceKm <= maxDistance;

        return ageMatch && distanceMatch;
      }).toList();
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        initialAgeRange: ageRange,
        initialDistance: maxDistance,
        onApplyFilter: (newAgeRange, newMaxDistance) {
          setState(() {
            ageRange = newAgeRange;
            maxDistance = newMaxDistance;
          });
          _applyFilters();
        },
      ),
    );
  }
}
