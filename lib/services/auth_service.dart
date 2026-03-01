import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata', // Scope for Drive App Data folder
    ],
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<void> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      notifyListeners();
    } catch (error) {
      if (kDebugMode) {
        print('Google Sign-In Error: $error');
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
    notifyListeners();
  }

  // Helper to get the authenticated client for Drive API
  GoogleSignIn get googleSignIn => _googleSignIn;
}
