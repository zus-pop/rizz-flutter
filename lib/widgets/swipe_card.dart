import 'package:flutter/material.dart';
import 'package:rizz_mobile/models/user_profile.dart';

class SwipeCard extends StatefulWidget {
  final UserProfile profile;

  const SwipeCard({super.key, required this.profile});

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  int currentImageIndex = 0;

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
            // Background image with tap zones for navigation
            Stack(
              children: [
                GestureDetector(
                  onTapUp: (details) {
                    if (widget.profile.imageUrls.length > 1) {
                      final width = MediaQuery.of(context).size.width;
                      final tapPosition = details.localPosition.dx;

                      if (tapPosition < width * 0.5) {
                        _previousImage();
                      } else {
                        _nextImage();
                      }
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: widget.profile.imageUrls.isNotEmpty
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
                    child: widget.profile.imageUrls.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                ),

                // Left tap zone indicator
                if (widget.profile.imageUrls.length > 1)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Container(color: Colors.transparent),
                  ),

                // Right tap zone indicator
                if (widget.profile.imageUrls.length > 1)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: Container(color: Colors.transparent),
                  ),
              ],
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

            // User information
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and age
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${widget.profile.name}, ${widget.profile.age}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Info button
                        GestureDetector(
                          onTap: () => _showProfileDetails(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Location
                    Row(
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

                    const SizedBox(height: 8),

                    // Bio (truncated)
                    Text(
                      widget.profile.bio,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // Interests chips
                    Wrap(
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
                            color: Color(0xFFfa5eff).withValues(alpha: 0.3),
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
                  ],
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
                        height: 3,
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
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
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
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF080026), // Secondary color background
              borderRadius: BorderRadius.only(
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
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        widget.profile.imageUrls[index],
                                      ),
                                      fit: BoxFit.cover,
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
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: Color(0xFFfa5eff),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.profile.location,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFfa5eff),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                widget.profile.bio,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Text(
                                'Interests',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFfa5eff),
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
                                      color: Color(
                                        0xFFfa5eff,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: Color(
                                          0xFFfa5eff,
                                        ).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      interest,
                                      style: TextStyle(
                                        color: Color(0xFFfa5eff),
                                        fontSize: 14,
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
