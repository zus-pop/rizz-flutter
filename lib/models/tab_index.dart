import 'package:flutter/material.dart';

// Enum for bottom navigation tab indices
enum TabIndex {
  discover,
  liked,
  chat,
  profile;

  // Get the integer value of the enum
  int get value => index;

  // Get display name
  String get displayName {
    switch (this) {
      case TabIndex.discover:
        return 'Khám phá';
      case TabIndex.liked:
        return 'Đã thích';
      case TabIndex.chat:
        return 'Tin nhắn';
      case TabIndex.profile:
        return 'Hồ sơ';
    }
  }

  // Get icon for the tab
  IconData get icon {
    switch (this) {
      case TabIndex.discover:
        return Icons.home;
      case TabIndex.liked:
        return Icons.favorite;
      case TabIndex.chat:
        return Icons.chat;
      case TabIndex.profile:
        return Icons.person;
    }
  }
}
