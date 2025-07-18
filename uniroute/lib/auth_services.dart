import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // Updated package
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthServices {
  // Constants
  static const String _userCollection = 'users';
  static const String _userRoleKey = 'userRole';
  static const String _defaultRole = UserRoles.student;

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
      // 1. Perform the sign-in request
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // 2. Create Firebase credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // 3. Sign in to Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // 4. Update display name if available (only provided on first login)
      if (credential.givenName != null && credential.familyName != null) {
        await userCredential.user?.updateDisplayName(
          '${credential.givenName} ${credential.familyName}',
        );
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
      String email, String password) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
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
      // No need to sign out from Apple as it's one-time per session

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userRoleKey);
    } catch (e) {
      debugPrint("Sign out error: $e");
    }
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