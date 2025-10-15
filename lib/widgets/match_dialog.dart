import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rizz_mobile/models/tab_index.dart';
import 'package:rizz_mobile/models/user.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class MatchDialog extends StatefulWidget {
  final User matchedUser;
  final User? currentUser;

  const MatchDialog({super.key, required this.matchedUser, this.currentUser});

  static void show(
    BuildContext context,
    User matchedUser, {
    User? currentUser,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) =>
          MatchDialog(matchedUser: matchedUser, currentUser: currentUser),
    );
  }

  @override
  State<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<MatchDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );

    // Start animations
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _bounceController.forward();
    });

    // Trigger vibration when match occurs
    _triggerMatchVibration();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _triggerMatchVibration() async {
    try {
      // Use Flutter's built-in haptic feedback for reliability
      await HapticFeedback.heavyImpact();

      // Add celebration pattern
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.mediumImpact();

      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Silently handle vibration errors (some devices don't support it)
      debugPrint('Vibration not supported: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                context.primary.withValues(alpha: 0.9),
                Colors.pink.withValues(alpha: 0.8),
                Colors.purple.withValues(alpha: 0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: context.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated heart icon
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_bounceAnimation.value * 0.2),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 48,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Match title with animation
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _bounceAnimation.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Left celebration icon
                          Icon(
                            Icons.celebration,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          // Match text
                          Text(
                            'It\'s a Match!',
                            style: AppTheme.headline2.copyWith(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 12),
                          // Right celebration icon
                          Icon(
                            Icons.celebration,
                            color: Colors.white,
                            size: 32,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Avatar row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Current user avatar
                    _buildAvatar(
                      widget.currentUser?.imageUrls?.firstOrNull,
                      widget.currentUser?.getFullName() ?? 'You',
                      isLeft: true,
                    ),

                    const SizedBox(width: 16),

                    // Heart icon in center
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Matched user avatar
                    _buildAvatar(
                      widget.matchedUser.imageUrls?.firstOrNull,
                      widget.matchedUser.getFullName(),
                      isLeft: false,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Match message
                Text(
                  'You and ${widget.matchedUser.getFullName()} liked each other!',
                  style: AppTheme.body1.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        child: Text(
                          'Keep Swiping',
                          style: AppTheme.button.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to chat tab
                          BottomTabPage.navigateToTab(context, TabIndex.chat);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: context.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Start Chatting',
                          style: AppTheme.button.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? imageUrl, String name, {required bool isLeft}) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: context.surface.withValues(alpha: 0.5),
                      child: Icon(
                        Icons.person,
                        color: context.onSurface.withValues(alpha: 0.5),
                        size: 32,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: context.surface.withValues(alpha: 0.5),
                      child: Icon(
                        Icons.person,
                        color: context.onSurface.withValues(alpha: 0.5),
                        size: 32,
                      ),
                    ),
                  )
                : Container(
                    color: context.surface.withValues(alpha: 0.5),
                    child: Icon(
                      Icons.person,
                      color: context.onSurface.withValues(alpha: 0.5),
                      size: 32,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Text(
            name,
            style: AppTheme.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
