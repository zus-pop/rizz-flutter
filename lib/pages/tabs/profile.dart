import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:rizz_mobile/models/user.dart';
import 'package:rizz_mobile/pages/photo_gallery_page.dart';
import 'package:rizz_mobile/pages/settings_page.dart';
import 'package:rizz_mobile/pages/voice_recording_page.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/services/firebase_database_service.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile>
    with
        AutomaticKeepAliveClientMixin<Profile>,
        TickerProviderStateMixin<Profile> {
  List<String> selectedImages = [];

  // Animation controller for badge gradient
  late AnimationController _gradientAnimationController;

  // Current user data
  User? _currentUser;
  final FirebaseDatabaseService _firebaseDatabase = FirebaseDatabaseService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Initialize gradient animation (4 seconds for smooth sweeping shimmer)
    _gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Fetch current user data
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final authProvider = context.read<AuthenticationProvider>();
      if (authProvider.userId != null) {
        final user = await _firebaseDatabase.getUserById(authProvider.userId!);
        if (mounted) {
          setState(() {
            _currentUser = user;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching current user: $e');
    }
  }

  @override
  void dispose() {
    _gradientAnimationController.dispose();
    super.dispose();
  }

  // Image methods moved to PhotoGalleryPage

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        final isRizzPlus = authProvider.isRizzPlus;
        return Scaffold(
          backgroundColor: context.colors.surface,
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 50.0),
                    child: Column(
                      children: [
                        // Profile Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hồ sơ',
                              style: AppTheme.headline3.copyWith(
                                color: context.onSurface,
                                fontSize: 33,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _navigateToSettings(context),
                              icon: Icon(
                                Icons.settings,
                                color: context.onSurface,
                                size: 33,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Profile Avatar with Verification
                        Center(
                          child: GestureDetector(
                            onTap: _navigateToPhotoGallery,
                            child: Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: context.primary,
                                      width: 3,
                                    ),
                                  ),
                                  child: selectedImages.isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: selectedImages.first,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            placeholder: (context, url) =>
                                                Container(
                                                  color: context.primary
                                                      .withValues(alpha: 0.1),
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: context.primary,
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                                      color: context.primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 60,
                                                        color: context.primary,
                                                      ),
                                                    ),
                                          ),
                                        )
                                      : _currentUser?.imageUrls != null &&
                                            _currentUser!.imageUrls!.isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                _currentUser!.imageUrls!.first,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            placeholder: (context, url) =>
                                                Container(
                                                  color: context.primary
                                                      .withValues(alpha: 0.1),
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color: context.primary,
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                                      color: context.primary
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      child: Icon(
                                                        Icons.person,
                                                        size: 60,
                                                        color: context.primary,
                                                      ),
                                                    ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              50,
                                            ),
                                            color: context.primary.withValues(
                                              alpha: 0.1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            size: 60,
                                            color: context.primary,
                                          ),
                                        ),
                                ),
                                // Edit photo icon
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: context.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: .2,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Profile Name
                        Text(
                          _currentUser != null
                              ? '${_currentUser!.getFullName()}, ${_currentUser!.getAge()}'
                              : 'Loading...',
                          style: AppTheme.headline3.copyWith(
                            color: context.onSurface,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Rizz Plus Section - Conditional based on plan
                        if (isRizzPlus) ...[
                          // Premium User - Show Benefits
                          AnimatedBuilder(
                            animation: _gradientAnimationController,
                            builder: (context, child) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.lerp(
                                        const Color(
                                          0xFFfa5eff,
                                        ), // App's primary purple
                                        const Color(0xFFc71585), // Deep pink
                                        _gradientAnimationController.value *
                                            0.3,
                                      )!,
                                      const Color(
                                        0xFFfa5eff,
                                      ), // App's primary purple
                                      const Color(0xFF9c27b0), // Purple accent
                                      Color.lerp(
                                        const Color(
                                          0xFFfa5eff,
                                        ), // App's primary purple
                                        const Color(0xFFe91e63), // Pink accent
                                        _gradientAnimationController.value *
                                            0.2,
                                      )!,
                                    ],
                                    stops: const [0.0, 0.3, 0.7, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFfa5eff,
                                    ).withValues(alpha: 0.8),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFfa5eff,
                                      ).withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: const Color(
                                        0xFFc71585,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Premium sparkle effects using app colors
                                    Positioned(
                                      top: 10,
                                      right: 20,
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        size: 18,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 15,
                                      left: 15,
                                      child: Icon(
                                        Icons.star,
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        size: 14,
                                      ),
                                    ),
                                    Positioned(
                                      top: 30,
                                      left: 25,
                                      child: Icon(
                                        Icons.brightness_1,
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        size: 10,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.25,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.4),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.diamond,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Rizz Plus',
                                                  style: AppTheme.headline4
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  1,
                                                                ),
                                                            blurRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        _buildPremiumFeature(
                                          Icons.mic,
                                          'Ghi âm không giới hạn thời gian',
                                        ),
                                        const SizedBox(height: 10),
                                        _buildPremiumFeature(
                                          Icons.smart_toy,
                                          'AI gợi ý tin nhắn khi chat',
                                        ),
                                        const SizedBox(height: 10),
                                        _buildPremiumFeature(
                                          Icons.visibility,
                                          'Xem chi tiết hồ sơ đầy đủ',
                                        ),
                                        const SizedBox(height: 10),
                                        _buildPremiumFeature(
                                          Icons.priority_high,
                                          'Lọc hồ sơ nâng cao',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          // Free User - Upgrade Prompt
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(
                                    0xFFfa5eff,
                                  ), // App's primary purple
                                  const Color(0xFFe91e63), // Pink accent
                                  const Color(0xFF9c27b0), // Purple accent
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(
                                  0xFFfa5eff,
                                ).withValues(alpha: 0.8),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFfa5eff,
                                  ).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 3,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Premium sparkle effects using app colors
                                Positioned(
                                  top: 15,
                                  right: 25,
                                  child: Icon(
                                    Icons.auto_awesome,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    size: 18,
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 20,
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.white.withValues(alpha: 0.3),
                                    size: 14,
                                  ),
                                ),
                                Positioned(
                                  top: 35,
                                  left: 30,
                                  child: Icon(
                                    Icons.brightness_1,
                                    color: Colors.white.withValues(alpha: 0.2),
                                    size: 10,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.4,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.diamond,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Nâng cấp Rizz Plus',
                                              style: AppTheme.headline4
                                                  .copyWith(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                        blurRadius: 2,
                                                      ),
                                                    ],
                                                  ),
                                            ),
                                            Text(
                                              '💎 Trải nghiệm Plus',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.9,
                                                ),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Mở khóa các tính năng Plus:',
                                      style: AppTheme.body2.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _buildUpgradeFeature(
                                      Icons.mic,
                                      'Ghi âm không giới hạn thời gian',
                                    ),
                                    const SizedBox(height: 10),
                                    _buildUpgradeFeature(
                                      Icons.smart_toy,
                                      'AI gợi ý tin nhắn khi chat',
                                    ),
                                    const SizedBox(height: 10),
                                    _buildUpgradeFeature(
                                      Icons.visibility,
                                      'Xem chi tiết hồ sơ đầy đủ',
                                    ),
                                    const SizedBox(height: 10),
                                    _buildUpgradeFeature(
                                      Icons.priority_high,
                                      'Lọc hồ sơ nâng cao',
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final status =
                                              await RevenueCatUI.presentPaywallIfNeeded(
                                                "premium",
                                                displayCloseButton: true,
                                              );
                                          if (status ==
                                              PaywallResult.purchased) {
                                            authProvider.isRizzPlus = true;
                                          } else if (status ==
                                              PaywallResult.restored) {
                                            debugPrint("Restored");
                                          } else {
                                            debugPrint("No purchased occur");
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(
                                            0xFFfa5eff,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 4,
                                          shadowColor: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.auto_awesome,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Nâng cấp ngay',
                                              style: AppTheme.button.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Voice Recording Card
                        GestureDetector(
                          onTap: _navigateToVoiceRecording,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: context.outline.withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Giọng nói của tôi',
                                      style: AppTheme.headline4.copyWith(
                                        color: context.onSurface,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: context.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _navigateToVoiceRecording,
                                        icon: const Icon(Icons.mic),
                                        label: const Text('Quản lý giọng nói'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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

                        const SizedBox(height: 24),

                        // Photo Gallery Card
                        GestureDetector(
                          onTap: _navigateToPhotoGallery,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: context.outline.withValues(alpha: 0.5),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ảnh của tôi',
                                      style: AppTheme.headline4.copyWith(
                                        color: context.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${(_currentUser?.imageUrls?.length ?? selectedImages.length)}/6',
                                      style: AppTheme.body2.copyWith(
                                        color: context.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _navigateToPhotoGallery,
                                        icon: const Icon(Icons.photo_library),
                                        label: const Text('Quản lý ảnh'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: context.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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

                        const SizedBox(height: 24),

                        //   // Quick Actions
                        //   Column(
                        //     children: [
                        //       _buildQuickAction(
                        //         'Những người tôi thích',
                        //         'Xem ai bạn đã thích',
                        //         Icons.favorite_outline,
                        //         _viewMyLikes,
                        //       ),
                        //       // _buildQuickAction(
                        //       //   'Người dùng bị chặn',
                        //       //   'Quản lý hồ sơ bị chặn',
                        //       //   Icons.block_outlined,
                        //       //   _viewBlockedUsers,
                        //       // ),
                        //       // _buildQuickAction(
                        //       //   'Trợ giúp & Hỗ trợ',
                        //       //   'Nhận trợ giúp hoặc liên hệ hỗ trợ',
                        //       //   Icons.help_outline,
                        //       //   _getHelp,
                        //       // ),
                        //     ],
                        //   ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.verified, color: const Color(0xFFfa5eff), size: 18),
        ],
      ),
    );
  }

  Widget _buildUpgradeFeature(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.white70, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFfa5eff), Color(0xFFe91e63)],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFfa5eff).withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Text(
              'PLUS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: context.outline.withValues(alpha: 1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: context.primary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.body2.copyWith(
                          color: context.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.onSurface.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewMyLikes() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('My likes coming soon!')));
  }

  // void _viewBlockedUsers() {
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(const SnackBar(content: Text('Blocked users coming soon!')));
  // }

  // void _getHelp() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text('Help & support coming soon!')),
  //   );
  // }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _navigateToPhotoGallery() {
    List<String> imageUrls = [];

    // Use user's images if available, otherwise use selected images
    if (_currentUser?.imageUrls != null &&
        _currentUser!.imageUrls!.isNotEmpty) {
      imageUrls = List.from(_currentUser!.imageUrls!);
    } else if (selectedImages.isNotEmpty) {
      imageUrls = List.from(selectedImages);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoGalleryPage(initialImageUrls: imageUrls),
      ),
    ).then((value) {
      // Refresh the profile after returning from photo gallery
      _fetchCurrentUser();
    });
  }

  void _navigateToVoiceRecording() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoiceRecordingPage()),
    );
  }
}
