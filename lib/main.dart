import 'package:flutter/material.dart';
import 'package:rizz_mobile/pages/bottom_tab_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Rizz",
      theme: ThemeData(primaryColor: Color.fromRGBO(250, 94, 255, 1)),
      home: BottomTabPage(),
    );
  }
}
