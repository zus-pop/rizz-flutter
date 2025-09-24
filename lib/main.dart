import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/firebase_options.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/pages/details/detail_chat.dart';
import 'package:rizz_mobile/pages/onboarding_screen.dart';
import 'package:rizz_mobile/pages/test.dart';
import 'package:rizz_mobile/providers/auth_provider.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/services/onboarding_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) {
    debugPrint('[On App Message]: ${remoteMessage.notification?.title}');
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
    debugPrint('[Message]: ${remoteMessage.notification?.title}');
  });
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage remoteMessage,
    ) async {
  debugPrint('[Background Message]: ${remoteMessage.notification?.title}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: "Rizz",
        theme: ThemeData(primaryColor: Color(0xFFfa5eff)),
        home: const SplashWrapper(),
        routes: {
          '/home': (context) => BottomTabPage(),
          '/detail_chat': (context) => const DetailChat(),
          '/onboarding': (context) => const OnboardingScreen(),
        },
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    // Delay nhỏ để tránh jerky animation
    await Future.delayed(const Duration(milliseconds: 500));

    final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();

    if (mounted) {
      if (hasSeenOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomTabPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfa5eff),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'Rizz',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
