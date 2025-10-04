import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _googleSignin = GoogleSignIn.instance;
  Future<GoogleSignInAccount> signInWithGoogle() async {
    await _googleSignin.initialize();
    final googleUser = await _googleSignin.authenticate();
    return googleUser;
  }

  Future<void> googleSignOut() async {
    await _googleSignin.signOut();
  }
}
