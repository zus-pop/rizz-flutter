import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rizz_mobile/models/user.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static AudioPlayer? _currentPlayer;

  static void play(AudioPlayer player) {
    // Stop the currently playing audio if different from the new one
    if (_currentPlayer != null && _currentPlayer != player) {
      _currentPlayer!.stop();
    }
    _currentPlayer = player;
  }

  static void stop(AudioPlayer player) {
    if (_currentPlayer == player) {
      _currentPlayer = null;
    }
  }
}

class Liked extends StatefulWidget {
  const Liked({super.key});

  @override
  State<Liked> createState() => _LikedState();
}

class _LikedState extends State<Liked>
    with AutomaticKeepAliveClientMixin<Liked> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Consumer<AuthenticationProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userId == null) {
            return const Center(child: Text('Vui lòng đăng nhập'));
          }

          return _LikedContent(currentUserId: authProvider.userId!);
        },
      ),
    );
  }
}

class _LikedContent extends StatefulWidget {
  final String currentUserId;

  const _LikedContent({required this.currentUserId});

  @override
  State<_LikedContent> createState() => _LikedContentState();
}

class _LikedContentState extends State<_LikedContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> _filterOutExistingMatches(List<String> userIds) async {
    if (userIds.isEmpty) return userIds;

    try {
      // Query matches where current user is involved
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: widget.currentUserId)
          .get();

      // Extract matched user IDs
      final matchedUserIds = <String>{};
      for (final doc in matchesSnapshot.docs) {
        final data = doc.data();
        final users = List<String>.from(data['users'] ?? []);
        matchedUserIds.addAll(users.where((id) => id != widget.currentUserId));
      }

      // Filter out matched users
      return userIds.where((id) => !matchedUserIds.contains(id)).toList();
    } catch (e) {
      debugPrint('Error filtering matches: $e');
      // Return original list if there's an error
      return userIds;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // People who liked you section
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collectionGroup('likes')
              .where('targetUserId', isEqualTo: widget.currentUserId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, likedBySnapshot) {
            if (likedBySnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (likedBySnapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Lỗi tải dữ liệu',
                    style: AppTheme.body1.copyWith(color: context.error),
                  ),
                ),
              );
            }

            final likedByUserIds = <String>{};
            final likedByDocs = likedBySnapshot.data?.docs ?? [];
            for (final doc in likedByDocs) {
              final pathSegments = doc.reference.path.split('/');
              final likerId = pathSegments[1];
              if (likerId != widget.currentUserId) {
                likedByUserIds.add(likerId);
              }
            }

            // Filter out users who are already matches
            return FutureBuilder<List<String>>(
              future: _filterOutExistingMatches(likedByUserIds.toList()),
              builder: (context, matchesFilterSnapshot) {
                if (matchesFilterSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final filteredUserIds = matchesFilterSnapshot.data ?? [];

                return _buildSection(
                  context,
                  'Những Người Thích Bạn',
                  'Những người quan tâm đến bạn',
                  filteredUserIds,
                  isLikedBy: true,
                );
              },
            );
          },
        ),

        const SizedBox(height: 24),

        // People you liked section - COMMENTED OUT
        /*
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(widget.currentUserId)
              .collection('likes')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, likedSnapshot) {
            if (likedSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (likedSnapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Error loading data',
                    style: AppTheme.body1.copyWith(color: context.error),
                  ),
                ),
              );
            }

            final likedUserIds = <String>{};
            final likedDocs = likedSnapshot.data?.docs ?? [];
            for (final doc in likedDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final targetUserId = data['targetUserId'] as String?;
              if (targetUserId != null &&
                  targetUserId != widget.currentUserId) {
                likedUserIds.add(targetUserId);
              }
            }

            return _buildSection(
              context,
              'People You Like',
              'People you\'ve shown interest in',
              likedUserIds.toList(),
              isLiked: true,
            );
          },
        ),
        */

        // Bottom padding
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String subtitle,
    List<String> userIds, {
    bool isLikedBy = false,
    bool isLiked = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTheme.headline4.copyWith(
                  color: context.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${userIds.length}',
                  style: AppTheme.body2.copyWith(
                    color: context.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Section subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              style: AppTheme.body2.copyWith(
                color: context.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Users grid or empty state
        SizedBox(
          height: _calculateGridHeight(userIds.length),
          child: userIds.isEmpty
              ? _buildSectionEmptyState(context, title)
              : _buildUsersGrid(
                  context,
                  userIds,
                  isLikedBy: isLikedBy,
                  isLiked: isLiked,
                ),
        ),
      ],
    );
  }

  double _calculateGridHeight(int itemCount) {
    if (itemCount == 0) return 200; // Empty state height

    // Grid with 2 columns, aspect ratio 3:5
    // Each row height = itemWidth * (5/3) + mainAxisSpacing
    // itemWidth = (screenWidth - padding - crossAxisSpacing) / 2
    // But for simplicity, let's use approximate calculations

    const int crossAxisCount = 2;
    const double aspectRatio = 3 / 5; // width:height ratio
    const double crossAxisSpacing = 12;
    const double mainAxisSpacing = 12;
    const double horizontalPadding = 32; // 16 * 2

    // Get screen width (approximate)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth =
        screenWidth - horizontalPadding - crossAxisSpacing;
    final double itemWidth = availableWidth / crossAxisCount;
    final double itemHeight =
        itemWidth /
        aspectRatio; // Since aspectRatio = width/height, height = width/aspectRatio

    final int rowCount = (itemCount / crossAxisCount).ceil();
    final double totalHeight =
        (rowCount * itemHeight) + ((rowCount - 1) * mainAxisSpacing);

    // Add some padding
    return totalHeight + 20;
  }

  Widget _buildSectionEmptyState(BuildContext context, String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            title.contains('You Like')
                ? Icons.favorite_border
                : Icons.visibility,
            size: 48,
            color: context.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title.contains('You Like')
                ? 'Chưa gửi lượt thích nào'
                : 'Chưa nhận được lượt thích nào',
            style: AppTheme.body1.copyWith(
              color: context.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.contains('You Like')
                ? 'Những người bạn thích sẽ xuất hiện ở đây'
                : 'Những người thích bạn sẽ xuất hiện ở đây',
            style: AppTheme.body2.copyWith(
              color: context.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUsersGrid(
    BuildContext context,
    List<String> userIds, {
    bool isMatch = false,
    bool isLikedBy = false,
    bool isLiked = false,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 5,
      ),
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final userId = userIds[index];
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(userId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard();
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildErrorCard();
            }

            final user = User.fromFirestore(
              snapshot.data! as DocumentSnapshot<Map<String, dynamic>>,
              null,
            );
            final userWithId = user.copyWithId(userId);

            return _buildInteractionCard(
              context,
              userWithId,
              isMatch: isMatch,
              isLikedBy: isLikedBy,
              isLiked: isLiked,
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: context.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.surface.withValues(alpha: 0.5),
        border: Border.all(
          color: context.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(Icons.error_outline, color: context.error, size: 32),
      ),
    );
  }

  Widget _buildInteractionCard(
    BuildContext context,
    User profile, {
    bool isMatch = false,
    bool isLikedBy = false,
    bool isLiked = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.outline.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.onSurface.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: context.surface,
          child: Column(
            children: [
              // Header with like indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.surface.withValues(alpha: 0.9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLikedBy) ...[
                      Icon(Icons.visibility, color: context.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Đã thích bạn',
                        style: TextStyle(
                          color: context.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else if (isLiked) ...[
                      Icon(
                        Icons.favorite_border,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bạn đã thích',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Profile info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      profile.getFullName(),
                      style: TextStyle(
                        color: context.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile.getAge()}',
                      style: TextStyle(
                        color: context.onSurface.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Audio player section
              Expanded(child: _LikedAudioPlayer(profile: profile)),

              // Action buttons
              _buildActionButtons(
                context,
                profile,
                isMatch: isMatch,
                isLikedBy: isLikedBy,
                isLiked: isLiked,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    User profile, {
    bool isMatch = false,
    bool isLikedBy = false,
    bool isLiked = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.surface.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Left button - different actions based on type
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (profile.id != null) {
                    final profileProvider = Provider.of<ProfileProvider>(
                      context,
                      listen: false,
                    );
                    if (isLikedBy) {
                      // For people who liked you, you can pass (remove from their likes subcollection? No, pass means we don't want to see them)
                      await profileProvider.passProfile(profile.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã bỏ qua ${profile.getFullName()}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: context.outline,
                          ),
                        );
                      }
                    } else if (isLiked) {
                      // For people you liked, you can unlike (pass)
                      await profileProvider.passProfile(profile.id!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã bỏ thích ${profile.getFullName()}',
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: context.outline,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                        color: context.outline.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Icon(
                    isMatch ? Icons.close : Icons.close,
                    color: context.error,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),

          // Right button - like/chat action
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  if (profile.id != null) {
                    final profileProvider = Provider.of<ProfileProvider>(
                      context,
                      listen: false,
                    );
                    if (isLikedBy) {
                      // Like back someone who liked you - this creates a match if mutual
                      final isMatch = await profileProvider.likeProfile(
                        profile.id!,
                      );
                      if (context.mounted) {
                        if (isMatch) {
                          // Special match notification
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '🎉 Khớp với ${profile.getFullName()}!',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 4),
                              backgroundColor: Colors.pink,
                              action: SnackBarAction(
                                label: 'Xem',
                                textColor: Colors.white,
                                onPressed: () {
                                  // Navigate to liked tab to see the match
                                  // This would require a tab controller or navigation setup
                                },
                              ),
                            ),
                          );
                        } else {
                          // Regular like notification
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Đã thích lại ${profile.getFullName()}!',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: context.primary,
                            ),
                          );
                        }
                      }
                    } else if (isLiked) {
                      // Already liked, show message
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Bạn đã thích ${profile.getFullName()}',
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  }
                },
                child: SizedBox(
                  height: 48,
                  child: Icon(
                    isLikedBy ? Icons.favorite : Icons.favorite,
                    color: isLiked ? Colors.orange : context.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LikedAudioPlayer extends StatefulWidget {
  final User profile;

  const _LikedAudioPlayer({required this.profile});

  @override
  State<_LikedAudioPlayer> createState() => _LikedAudioPlayerState();
}

class _LikedAudioPlayerState extends State<_LikedAudioPlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isCompleted = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupAudioListeners();
    if (widget.profile.audioUrl != null) {
      _loadAudio();
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isCompleted = state == PlayerState.completed;
          if (state == PlayerState.completed) {
            _isPlaying = false;
            AudioManager.stop(_audioPlayer);
          }
        });
      }
    });
  }

  Future<void> _loadAudio() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _audioPlayer.setSource(UrlSource(widget.profile.audioUrl!));
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    AudioManager.stop(_audioPlayer);
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_hasError) {
      await _loadAudio();
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        AudioManager.stop(_audioPlayer);
      } else {
        if (_isCompleted ||
            (_position >= _duration && _duration > Duration.zero)) {
          await _audioPlayer.stop();
          await _audioPlayer.setSource(UrlSource(widget.profile.audioUrl!));
          await _audioPlayer.resume();
          AudioManager.play(_audioPlayer);
          setState(() {
            _isCompleted = false;
            _position = Duration.zero;
          });
        } else {
          await _audioPlayer.resume();
          AudioManager.play(_audioPlayer);
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio waveform visualization
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(Icons.graphic_eq, color: context.primary, size: 48),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Play/Pause button
          GestureDetector(
            onTap: _playPause,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.primary.withValues(alpha: 0.4),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: context.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : _hasError
                  ? Icon(Icons.error, color: context.onPrimary, size: 24)
                  : Icon(
                      _isPlaying
                          ? Icons.pause
                          : _isCompleted
                          ? Icons.replay
                          : Icons.play_arrow,
                      color: context.onPrimary,
                      size: 28,
                    ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
