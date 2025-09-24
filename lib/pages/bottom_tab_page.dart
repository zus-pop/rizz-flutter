import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/pages/tabs/chat.dart';
import 'package:rizz_mobile/pages/tabs/discover.dart';
import 'package:rizz_mobile/pages/tabs/liked.dart';
import 'package:rizz_mobile/pages/tabs/profile.dart';
import 'package:rizz_mobile/providers/auth_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';

class BottomTabPage extends StatefulWidget {
  const BottomTabPage({super.key});

  @override
  State<BottomTabPage> createState() => _BottomTabPageState();
}

class _BottomTabPageState extends State<BottomTabPage> {
  int _selectedIndex = 0;
  final padding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
  double gap = 10;
  static const List<Widget> _tabs = <Widget>[
    Discover(),
    Liked(),
    Chat(),
    Profile(),
  ];

  @override
  void initState() {
    // final state = context.read<AuthProvider>().authState;
    // if (state == AuthState.authenticated) {
    context.read<AuthProvider>().updateToken();
    // }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Center(child: _tabs.elementAt(_selectedIndex)),
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
                    tabs: const [
                      GButton(icon: Icons.home, text: 'Discover'),
                      GButton(icon: Icons.favorite, text: 'Liked'),
                      GButton(icon: Icons.chat, text: 'Chat'),
                      GButton(icon: Icons.person, text: 'Profile'),
                    ],
                    selectedIndex: _selectedIndex,
                    onTabChange: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
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
