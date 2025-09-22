import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/models/profile.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class Liked extends StatelessWidget {
  const Liked({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and notification count
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Matches',
                    style: AppTheme.headline2.copyWith(
                      color: context.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Consumer<ProfileProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.likedProfiles.length}',
                          style: AppTheme.body1.copyWith(
                            color: context.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This is a list of people who have liked you\nand your matches.',
                  style: AppTheme.body2.copyWith(
                    color: context.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Content with bottom padding to avoid tab bar
            Expanded(
              child: Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  final likedProfiles = provider.likedProfiles;

                  if (likedProfiles.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return _buildMatchesList(context, likedProfiles, provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList(
    BuildContext context,
    List<Profile> profiles,
    ProfileProvider provider,
  ) {
    final todayProfiles = profiles.take(4).toList();
    final yesterdayProfiles = profiles.skip(4).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        if (todayProfiles.isNotEmpty) ...[
          _buildDateSection(context, 'Today', todayProfiles, provider),
          const SizedBox(height: 24),
        ],
        if (yesterdayProfiles.isNotEmpty) ...[
          _buildDateSection(context, 'Yesterday', yesterdayProfiles, provider),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    String dateLabel,
    List<Profile> profiles,
    ProfileProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            dateLabel,
            style: AppTheme.body1.copyWith(
              fontWeight: FontWeight.w600,
              color: context.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return _buildMatchCard(context, profile, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 64, color: context.outline),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: AppTheme.headline4.copyWith(
                color: context.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'People who like you will appear here',
              style: AppTheme.body2.copyWith(
                color: context.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    Profile profile,
    ProfileProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        child: Stack(
          children: [
            Positioned.fill(child: _buildProfileImage(context, profile)),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: .3),
                      Colors.black.withValues(alpha: .8),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 60,
              left: 8,
              child: Text(
                '${profile.name}, ${profile.age}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      color: Colors.black54,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildActionButtons(context, profile, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(BuildContext context, Profile profile) {
    final imageUrl = profile.imageUrls.isNotEmpty
        ? profile.imageUrls.first
        : '';

    if (imageUrl.isEmpty) {
      return Container(
        color: context.colors.surfaceContainerHigh,
        child: Icon(Icons.person, size: 50, color: context.outline),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: context.colors.surfaceContainerHigh,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: context.colors.surfaceContainerHigh,
        child: Icon(Icons.error, size: 50, color: context.outline),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Profile profile,
    ProfileProvider provider,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 30,
          sigmaY: 30,
          tileMode: TileMode.decal,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.surface.withValues(alpha: 0.4),
          ),
          child: Row(
            children: [
              // Pass button (left half)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await provider.passLikedProfile(profile.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Passed ${profile.name}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: context.error,
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 56,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.white30, width: 1),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),

              // Like button (right half)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await provider.likeProfile(profile.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Liked ${profile.name} again!'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppTheme.success(context),
                          ),
                        );
                      }
                    },
                    child: const SizedBox(
                      height: 56,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
