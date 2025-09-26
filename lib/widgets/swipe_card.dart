import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/profile.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:rizz_mobile/pages/chatbot.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rizz_mobile/widgets/audio_player_dialog.dart';

class SwipeCard extends StatefulWidget {
  final Profile profile;

  const SwipeCard({super.key, required this.profile});

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  void _showChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Chatbot(profile: widget.profile),
        ),
      ),
    );
  }

  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    debugPrint(widget.profile.name);
    // Ensure currentImageIndex is valid for the current profile
    if (widget.profile.imageUrls.isEmpty) {
      currentImageIndex = 0;
    } else {
      currentImageIndex = 0.clamp(0, widget.profile.imageUrls.length - 1);
    }
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset image index when profile changes
    if (widget.profile != oldWidget.profile) {
      debugPrint(
        '${oldWidget.profile.name} was replaced by ${widget.profile.name}',
      );
      if (widget.profile.imageUrls.isEmpty) {
        currentImageIndex = 0;
      } else {
        currentImageIndex = 0.clamp(0, widget.profile.imageUrls.length - 1);
      }
    }
  }

  void _nextImage() {
    if (widget.profile.imageUrls.length > 1) {
      setState(() {
        currentImageIndex =
            (currentImageIndex + 1) % widget.profile.imageUrls.length;
      });
    }
  }

  void _previousImage() {
    if (widget.profile.imageUrls.length > 1) {
      setState(() {
        currentImageIndex = currentImageIndex > 0
            ? currentImageIndex - 1
            : widget.profile.imageUrls.length - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image:
                    widget.profile.imageUrls.isNotEmpty &&
                        currentImageIndex >= 0 &&
                        currentImageIndex < widget.profile.imageUrls.length
                    ? DecorationImage(
                        image: NetworkImage(
                          widget.profile.imageUrls[currentImageIndex],
                        ),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Handle image loading error
                        },
                      )
                    : null,
                color: widget.profile.imageUrls.isEmpty
                    ? Colors.grey[300]
                    : null,
              ),
              child:
                  widget.profile.imageUrls.isNotEmpty &&
                      currentImageIndex >= 0 &&
                      currentImageIndex < widget.profile.imageUrls.length
                  ? CachedNetworkImage(
                      imageUrl: widget.profile.imageUrls[currentImageIndex],
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),

            // Gradient overlay for better text visibility
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Touch zones for image navigation - positioned on top
            if (widget.profile.imageUrls.length > 1) ...[
              // Left tap zone
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.4,
                child: GestureDetector(
                  onTap: _previousImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Right tap zone
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.4,
                child: GestureDetector(
                  onTap: _nextImage,
                  behavior: HitTestBehavior.translucent,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],

            // AI icon at top left
            Positioned(
              top: 40,
              left: 20,
              child: GestureDetector(
                onTap: () => _showChatbot(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // User information - with pointer events for info button only
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: false,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and age
                      Row(
                        children: [
                          // ...existing code for name, age, info button (remove AI icon here)...
                          const SizedBox(width: 8),
                          Expanded(
                            child: IgnorePointer(
                              child: Text(
                                '${widget.profile.name}, ${widget.profile.age}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Info button - only this should be tappable
                          GestureDetector(
                            onTap: () => _showProfileDetails(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Location
                      IgnorePointer(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.profile.location,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Bio (truncated)
                      IgnorePointer(
                        child: Text(
                          widget.profile.bio,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Interests chips
                      IgnorePointer(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: widget.profile.interests.take(3).map((
                            interest,
                          ) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: context.primary.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                interest,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Photo indicators
            if (widget.profile.imageUrls.length > 1)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Row(
                  children: widget.profile.imageUrls.asMap().entries.map((
                    entry,
                  ) {
                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: EdgeInsets.only(
                          right:
                              entry.key == widget.profile.imageUrls.length - 1
                              ? 0
                              : 4,
                        ),
                        decoration: BoxDecoration(
                          color: entry.key == currentImageIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Audio icon - positioned in top right corner
            if (widget.profile.audioUrl != null)
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => _showAudioModal(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAudioModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AudioPlayerDialog(
        audioUrl: widget.profile.audioUrl!,
        userName: widget.profile.name,
      ),
    );
  }

  void _showProfileDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.80,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        expand: false,
        snapSizes: [.75],
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Draggable handle bar area - larger touch target
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // Scrollable content that includes images and text
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Horizontal image gallery
                        if (widget.profile.imageUrls.isNotEmpty)
                          Container(
                            height: 250,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: PageView.builder(
                              itemCount: widget.profile.imageUrls.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.profile.imageUrls[index],
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          CircularProgressIndicator(),
                                      errorWidget: (context, url, error) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(
                                              Icons.error,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        // Profile content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile details
                              Text(
                                '${widget.profile.name}, ${widget.profile.age}',
                                style: AppTheme.headline1.copyWith(
                                  color: context.onSurface,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: context.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.profile.location,
                                    style: AppTheme.body1.copyWith(
                                      color: context.onSurface,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'About',
                                style: AppTheme.headline4.copyWith(
                                  color: context.primary,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                widget.profile.bio,
                                style: AppTheme.body1.copyWith(
                                  color: context.onSurface,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'Interests',
                                style: AppTheme.headline4.copyWith(
                                  color: context.primary,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: widget.profile.interests.map((
                                  interest,
                                ) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: context.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      interest,
                                      style: AppTheme.body2.copyWith(
                                        color: context.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(
                                height: 100,
                              ), // Extra space for bottom sheet
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
