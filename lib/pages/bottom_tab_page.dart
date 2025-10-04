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
import 'package:rizz_mobile/theme/app_theme.dart';

class BottomTabPage extends StatefulWidget {
  const BottomTabPage({super.key});

  @override
  State<BottomTabPage> createState() => _BottomTabPageState();
}

class _BottomTabPageState extends State<BottomTabPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
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
    context.read<AuthenticationProvider>().updateToken();
    _checkPremium();
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

  @override
  void dispose() {
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
            children: _tabs,
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
                      GButton(icon: Icons.home, text: 'Khám phá'),
                      GButton(icon: Icons.favorite, text: 'Đã thích'),
                      GButton(icon: Icons.chat, text: 'Tin nhắn'),
                      GButton(icon: Icons.person, text: 'Hồ sơ'),
                    ],
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
