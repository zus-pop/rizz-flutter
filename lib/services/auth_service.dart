import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rizz_mobile/utils/my_dio.dart';

class AuthService {
  final _googleSignin = GoogleSignIn.instance;
  Future<GoogleSignInAccount> signInWithGoogle() async {
    await _googleSignin.initialize();
    final googleUser = await _googleSignin.authenticate();
    final googleAuth = googleUser.authentication;
    const url = 'https://20e432bff7c6.ngrok-free.app/api/Auth/google';
    final response = await myDio.post(
      url,
      data: {'idToken': googleAuth.idToken},
    );
    debugPrint('Response: ${response.data}');
    return googleUser;
  }

  Future<void> googleSignOut() async {
    await _googleSignin.signOut();
  }
}
