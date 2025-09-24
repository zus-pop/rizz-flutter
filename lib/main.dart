import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/firebase_options.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/pages/details/detail_chat.dart';
import 'package:rizz_mobile/pages/test.dart';
import 'package:rizz_mobile/providers/auth_provider.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';

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
        home: Test(),
        routes: {'/home': (context) => BottomTabPage(),
          '/detail_chat': (context) => const DetailChat(),
        },
      ),
    );
  }
}