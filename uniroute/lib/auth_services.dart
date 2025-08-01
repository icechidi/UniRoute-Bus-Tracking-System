// auth_services.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthServices {
  // Constants
  static const String _keepSignedInKey = 'keep_signed_in';
  static const String _authTokenKey = 'auth_token';
  static const String _authEmailKey = 'auth_email';

  // Google Sign-In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '87170443990-f0ev561n5bin8f2mndsm62d0hnlhgdqs.apps.googleusercontent.com'
            : null,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Store token for auto-login
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await saveAuthData(token, userCredential.user?.email, true);
      }

      return userCredential;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      return null;
    }
  }

  // Apple Sign-In
  static Future<UserCredential?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Store token for auto-login
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await saveAuthData(token, userCredential.user?.email, true);
      }

      return userCredential;
    } catch (e) {
      debugPrint("Apple sign-in error: $e");
      return null;
    }
  }

  // Email/Password Sign-In
  static Future<UserCredential?> signInWithEmail(
      String email, String password, bool keepSignedIn) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Store token for auto-login
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await saveAuthData(token, email, keepSignedIn);
      }

      return userCredential;
    } catch (e) {
      debugPrint("Email login error: $e");
      return null;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keepSignedInKey);
      await prefs.remove(_authTokenKey);
      await prefs.remove(_authEmailKey);
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
  }

  // Auth persistence methods
  static Future<void> saveAuthData(
      String? token, String? email, bool keepSignedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepSignedInKey, keepSignedIn);
    if (keepSignedIn && token != null && email != null) {
      await prefs.setString(_authTokenKey, token);
      await prefs.setString(_authEmailKey, email);
    } else {
      await prefs.remove(_authTokenKey);
      await prefs.remove(_authEmailKey);
    }
  }

  static Future<bool> shouldKeepSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepSignedInKey) ?? false;
  }

  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  static Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authEmailKey);
  }

  // Get current Firebase user
  static User? getCurrentUser() => FirebaseAuth.instance.currentUser;
}
