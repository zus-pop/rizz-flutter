import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:rizz_mobile/widgets/filter_modal.dart';
import 'package:rizz_mobile/widgets/swipe_card.dart';

class Discover extends StatefulWidget {
  const Discover({super.key});

  @override
  State<Discover> createState() => _DiscoverState();
}

class _DiscoverState extends State<Discover>
    with AutomaticKeepAliveClientMixin<Discover> {
  final CardSwiperController controller = CardSwiperController();
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    // Initialize profiles when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().initialize();
    });
    debugPrint("It re-builded");
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          'Khám phá giọng nói',
          style: AppTheme.headline3.copyWith(
            color: context.primary,
            fontSize: 30,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _showFilterModal,
            icon: Icon(Icons.tune, color: context.primary, size: 36),
          ),
        ],
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          debugPrint(profileProvider.profiles.length.toString());
          // Handle different loading states
          if (profileProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải hồ sơ...',
                    style: AppTheme.body1.copyWith(color: context.onSurface),
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
                  Icon(Icons.error_outline, size: 64, color: context.error),
                  const SizedBox(height: 16),
                  Text(
                    'Lỗi khi tải hồ sơ',
                    style: AppTheme.headline4.copyWith(
                      color: context.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profileProvider.errorMessage ?? 'Unknown error',
                    style: AppTheme.body2.copyWith(
                      color: context.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => profileProvider.retry(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (profileProvider.isEmpty || profileProvider.profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: context.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Không còn hồ sơ để hiển thị',
                    style: AppTheme.headline4.copyWith(
                      color: context.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quay lại khi có thêm hồ sơ mới!',
                    style: AppTheme.body2.copyWith(
                      color: context.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          // Case 1: Profiles array has items - show swiper with action buttons
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
                  numberOfCardsDisplayed: profileProvider.profiles.length >= 2
                      ? 2
                      : 1,
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
                            child: const Center(child: Text('Không còn hồ sơ')),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: context.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: context.primary,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đang tải thêm...',
                          style: AppTheme.caption.copyWith(
                            color: context.onSurface,
                          ),
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
                        color: context.primary,
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
          color: context.surface,
          shape: BoxShape.circle,
          border: Border.all(color: context.outline.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: context.onSurface.withValues(alpha: 0.1),
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
        action = 'bỏ qua';
        if (previousIndex >= 0 &&
            previousIndex < profileProvider.profiles.length) {
          profileId = profileProvider.profiles[previousIndex].id;
          profileProvider.passProfile(profileId);
        }
        break;
      case CardSwiperDirection.right:
        action = 'đã thích';
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
              ? context.primary
              : context.outline,
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
    debugPrint("here");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterModal(
        initialAgeRange: profileProvider.ageRange,
        initialDistance: profileProvider.maxDistance,
        initialEmotion: profileProvider.emotionFilter,
        initialVoiceQuality: profileProvider.voiceQualityFilter,
        initialAccent: profileProvider.accentFilter,
        onApplyFilter:
            (
              newAgeRange,
              newMaxDistance,
              newEmotion,
              newVoiceQuality,
              newAccent,
            ) {
              profileProvider.applyFilters(
                ageRange: newAgeRange,
                maxDistance: newMaxDistance,
                emotion: newEmotion,
                voiceQuality: newVoiceQuality,
                accent: newAccent,
              );
            },
      ),
    );
  }
}
