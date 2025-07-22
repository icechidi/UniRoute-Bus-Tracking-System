import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthServices {
  // Constants
  static const String _userCollection = 'users';
  static const String _userRoleKey = 'userRole';
  static const String _defaultRole = UserRoles.student;
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

      // Get and store token for Google sign-in
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await saveAuthData(token, userCredential.user?.email, true);
      }

      await _handlePostSignIn(userCredential.user?.email);
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

      if (credential.givenName != null && credential.familyName != null) {
        await userCredential.user?.updateDisplayName(
          '${credential.givenName} ${credential.familyName}',
        );
      }

      // Get and store token for Apple sign-in
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await saveAuthData(token, userCredential.user?.email, true);
      }

      await _handlePostSignIn(userCredential.user?.email);
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

      // Get and store token for email sign-in
      final token = await userCredential.user?.getIdToken();
      if (token != null) {
        await saveAuthData(token, email, keepSignedIn);
      }

      await _handlePostSignIn(email);
      return userCredential;
    } catch (e) {
      debugPrint("Email login error: $e");
      return null;
    }
  }

  // Shared post-sign-in logic
  static Future<void> _handlePostSignIn(String? email) async {
    if (email == null) return;

    await FirebaseFirestore.instance.enableNetwork();
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final userDoc = await FirebaseFirestore.instance
        .collection(_userCollection)
        .doc(email)
        .get();

    if (userDoc.exists && userDoc.data()!.containsKey('role')) {
      prefs.setString(_userRoleKey, userDoc['role']);
    } else {
      await FirebaseFirestore.instance
          .collection(_userCollection)
          .doc(email)
          .set({
        'email': email,
        'role': _defaultRole,
      });
      prefs.setString(_userRoleKey, _defaultRole);
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userRoleKey);
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

  // Get saved user role
  static Future<String?> getSavedUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }
}

// User role constants
class UserRoles {
  static const String student = 'student';
  static const String driver = 'driver';
}
