import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';
import 'package:rizz_mobile/providers/user_profile_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProfileProvider())],
      child: MaterialApp(
        title: "Rizz",
        theme: ThemeData(primaryColor: Color.fromRGBO(250, 94, 255, 1)),
        home: BottomTabPage(),
      ),
    );
  }
}
