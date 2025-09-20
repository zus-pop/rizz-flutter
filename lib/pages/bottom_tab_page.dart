import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:rizz_mobile/pages/tabs/chat.dart';
import 'package:rizz_mobile/pages/tabs/discover.dart';
import 'package:rizz_mobile/pages/tabs/liked.dart';
import 'package:rizz_mobile/pages/tabs/profile.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Color(0xFF080026), // Secondary color background
      body: Stack(
        children: [
          Center(child: _tabs.elementAt(_selectedIndex)),
          Positioned(
            bottom: 5, // Distance from bottom
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF080026), // Secondary color background
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      spreadRadius: 2,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.0),
                  child: GNav(
                    rippleColor: Color(0xFFfa5eff).withValues(alpha: 0.3),
                    hoverColor: Color(0xFFfa5eff).withValues(alpha: 0.2),
                    gap: 8,
                    activeColor: Colors.white,
                    iconSize: 24,
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    duration: Duration(milliseconds: 400),
                    tabBackgroundColor: Color(
                      0xFFfa5eff,
                    ).withValues(alpha: 0.8),
                    color: Colors.white70,
                    tabs: [
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
