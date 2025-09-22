import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/models/profile.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';

class Liked extends StatelessWidget {
  const Liked({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Consumer<ProfileProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.likedProfiles.length}',
                          style: TextStyle(
                            color: Colors.pink[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
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
          _buildDateSection('Today', todayProfiles, provider),
          const SizedBox(height: 24),
        ],
        if (yesterdayProfiles.isNotEmpty) ...[
          _buildDateSection('Yesterday', yesterdayProfiles, provider),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildDateSection(
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
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
            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'People who like you will appear here',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
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
            color: Colors.black.withValues(alpha: .1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(child: _buildProfileImage(profile)),

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

  Widget _buildProfileImage(Profile profile) {
    final imageUrl = profile.imageUrls.isNotEmpty
        ? profile.imageUrls.first
        : '';

    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.person, size: 50, color: Colors.grey),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.error, size: 50, color: Colors.grey),
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
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4)),
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
                            backgroundColor: Colors.red[400],
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
                            backgroundColor: Colors.green[400],
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
