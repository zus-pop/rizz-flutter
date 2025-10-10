import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:rizz_mobile/firebase_options.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/pages/details/match_chat_detail_page.dart';
import 'package:rizz_mobile/pages/splash_screen.dart';
import 'package:rizz_mobile/providers/app_setting_provider.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/providers/profile_provider.dart';
import 'package:rizz_mobile/services/match_chat_service.dart';
import 'package:rizz_mobile/store_config.dart';
import 'package:rizz_mobile/utils/performance_optimizer.dart';

import 'constant.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env');
  if (kIsWeb) {
    StoreConfig(store: Store.rcBilling, apiKey: webApiKey);
  } else if (Platform.isIOS || Platform.isMacOS) {
    StoreConfig(store: Store.appStore, apiKey: appleApiKey);
  } else if (Platform.isAndroid) {
    // Run the app passing --dart-define=AMAZON=true
    const useAmazon = bool.fromEnvironment("amazon");
    StoreConfig(
      store: useAmazon ? Store.amazon : Store.playStore,
      apiKey: useAmazon ? amazonApiKey : googleApiKey,
    );
  }
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize optimized Firestore settings for match chat
  await MatchChatService.initializeFirestore();

  // Initialize performance optimizer
  PerformanceOptimizer.initialize();

  // Configure system UI for better performance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) {
    debugPrint('[On App Message]: ${remoteMessage.notification?.title}');
    if (remoteMessage.data['type'] == 'chat') {}
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) {
    debugPrint('[Message]: ${remoteMessage.notification?.title}');
  });

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await _configureSDK();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettingProvider(),
      child: const MyApp(),
    ),
  );
}

Future<void> _configureSDK() async {
  // Enable debug logs before calling `configure`.
  await Purchases.setLogLevel(LogLevel.debug);

  /*
    - appUserID is nil, so an anonymous ID will be generated automatically by the Purchases SDK. Read more about Identifying Users here: https://docs.revenuecat.com/docs/user-ids

    - PurchasesAreCompletedyBy is PurchasesAreCompletedByRevenueCat, so Purchases will automatically handle finishing transactions. Read more about completing purchases here: https://www.revenuecat.com/docs/migrating-to-revenuecat/sdk-or-not/finishing-transactions
    */
  PurchasesConfiguration configuration;
  if (StoreConfig.isForAmazonAppstore()) {
    configuration = AmazonConfiguration(StoreConfig.instance.apiKey)
      ..appUserID = null
      ..purchasesAreCompletedBy = const PurchasesAreCompletedByRevenueCat();
  } else {
    configuration = PurchasesConfiguration(StoreConfig.instance.apiKey)
      ..appUserID = null
      ..purchasesAreCompletedBy = const PurchasesAreCompletedByRevenueCat();
  }
  await Purchases.configure(configuration);
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
      child: const MyAppContent(),
    );
  }
}

class MyAppContent extends StatefulWidget {
  const MyAppContent({super.key});

  @override
  State<MyAppContent> createState() => _MyAppContentState();
}

class _MyAppContentState extends State<MyAppContent> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: false,
      title: "Rizz",
      theme: Provider.of<AppSettingProvider>(context).themeData,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => BottomTabPage(),
        '/match_chat_detail': (context) => const MatchChatDetailPage(),
      },
    );
  }
}
