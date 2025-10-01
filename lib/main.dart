import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/firebase_options.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/pages/details/detail_chat.dart';
import 'package:rizz_mobile/pages/splash_screen.dart';
import 'package:rizz_mobile/providers/app_setting_provider.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/services/simple_chat_service.dart';
import 'package:rizz_mobile/utils/performance_optimizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize optimized Firestore settings
  await SimpleChatService.initializeFirestore();

  // Initialize performance optimizer
  PerformanceOptimizer.initialize();

  // Configure system UI for better performance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Reduce Firebase messaging verbosity in production
  if (!kDebugMode) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) {
      // Handle message silently in production
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
      // Handle message silently in production
    });
  } else {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) {
      debugPrint('[On App Message]: ${remoteMessage.notification?.title}');
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
      debugPrint('[Message]: ${remoteMessage.notification?.title}');
    });
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(create: (_) => AppSettingProvider(), child: const MyApp()),
  );
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
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
      ],
      child: MaterialApp(
        showPerformanceOverlay: false,
        title: "Rizz",
        theme: Provider.of<AppSettingProvider>(context).themeData,
        home: const BottomTabPage(),
        routes: {
          '/home': (context) => BottomTabPage(),
          '/detail_chat': (context) => const DetailChat(),
        },
      ),
    );
  }
}
