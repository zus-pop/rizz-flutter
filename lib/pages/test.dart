import 'package:flutter/material.dart';
import 'package:rizz_mobile/services/auth_service.dart';

class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login with Google')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final user = await AuthService().signInWithGoogle();
                debugPrint(user.email);
              },
              child: Text('Login with Google'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AuthService().googleSignOut();
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
