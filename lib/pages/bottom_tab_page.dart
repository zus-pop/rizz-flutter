import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:rizz_mobile/constant.dart';
import 'package:rizz_mobile/pages/auth/login_page.dart';
import 'package:rizz_mobile/pages/tabs/chat.dart';
import 'package:rizz_mobile/pages/tabs/discover.dart';
import 'package:rizz_mobile/pages/tabs/liked.dart';
import 'package:rizz_mobile/pages/tabs/profile.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/models/tab_index.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class BottomTabPage extends StatefulWidget {
  const BottomTabPage({super.key});

  // Static method to navigate programmatically
  static void navigateToTab(BuildContext context, TabIndex tabIndex) {
    _BottomTabPageState.navigateToTab(context, tabIndex);
  }

  @override
  State<BottomTabPage> createState() => _BottomTabPageState();
}

class _BottomTabPageState extends State<BottomTabPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final padding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
  double gap = 10;

  // Static reference to current state for programmatic navigation
  static _BottomTabPageState? _currentState;

  // Static method to navigate programmatically
  static void navigateToTab(BuildContext context, TabIndex tabIndex) {
    if (_currentState != null) {
      debugPrint(
        'Found BottomTabPage state via static reference, navigating to: ${tabIndex.name}',
      );
      _currentState!._navigateToTab(tabIndex.value);
    } else {
      debugPrint(
        'Could not find BottomTabPage state for navigation - static reference is null',
      );
    }
  }

  // Generate tab widgets from enum
  List<Widget> get _tabWidgets {
    return TabIndex.values.map((tabIndex) {
      switch (tabIndex) {
        case TabIndex.discover:
          return const Discover();
        case TabIndex.liked:
          return const Liked();
        case TabIndex.chat:
          return const Chat();
        case TabIndex.profile:
          return const Profile();
      }
    }).toList();
  }

  // Generate tab buttons from enum
  List<GButton> get _tabButtons {
    final buttons = TabIndex.values.map((tabIndex) {
      return GButton(icon: tabIndex.icon, text: tabIndex.displayName);
    }).toList();
    debugPrint('Generated ${buttons.length} tab buttons');
    return buttons;
  }

  @override
  void initState() {
    _currentState = this; // Store reference to current state
    context.read<AuthenticationProvider>().updateToken();
    _checkPremium();

    // Listen to page controller changes
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _selectedIndex) {
        setState(() {
          _selectedIndex = page;
        });
      }
    });

    super.initState();
  }

  Future<void> _checkPremium() async {
    try {
      final userId = context.read<AuthenticationProvider>().userId;
      if (userId == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }
      final result = await Purchases.logIn(userId);
      final customerInfo = result.customerInfo;
      debugPrint("yes it is: ${result.created}");
      final isRizzPlus = customerInfo.entitlements.all[entitlementID]!.isActive;
      debugPrint('Is user premium: ${isRizzPlus.toString()}');
      if (mounted) {
        context.read<AuthenticationProvider>().isRizzPlus = isRizzPlus;
      }
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }
  }

  void _onTabChange(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  // Public method to navigate programmatically
  void _navigateToTab(int index) {
    debugPrint('Navigating to tab index: $index, current: $_selectedIndex');
    if (index >= 0 && index < _tabWidgets.length && _selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
      debugPrint('Navigation completed to index: $index');
    } else {
      debugPrint('Navigation skipped - invalid index or same tab');
    }
  }

  @override
  void dispose() {
    _currentState = null; // Clear reference
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _tabWidgets,
          ),
          Positioned(
            bottom: 5, // Distance from bottom
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: context.surface,
                  borderRadius: BorderRadius.circular(30.0),
                  border: Border.all(
                    color: context.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.onSurface.withValues(alpha: 0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: GNav(
                    key: ValueKey(
                      _selectedIndex,
                    ), // Force rebuild when index changes
                    rippleColor: context.primary.withValues(alpha: 0.3),
                    hoverColor: context.primary.withValues(alpha: 0.2),
                    gap: 8,
                    activeColor: context.onPrimary,
                    iconSize: 24,
                    tabMargin: const EdgeInsetsGeometry.symmetric(
                      vertical: 5,
                      horizontal: 5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                    duration: const Duration(milliseconds: 400),
                    tabBackgroundColor: context.primary,
                    color: context.onSurface.withValues(alpha: 0.6),
                    tabs: _tabButtons,
                    selectedIndex: _selectedIndex,
                    onTabChange: _onTabChange,
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
