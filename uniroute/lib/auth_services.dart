import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

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

      await FirebaseFirestore.instance.enableNetwork();
      await Future.delayed(const Duration(milliseconds: 500));

      final userEmail = userCredential.user?.email;
      if (userEmail != null) {
        final prefs = await SharedPreferences.getInstance();
        final userDoc = await FirebaseFirestore.instance
            .collection(_userCollection)
            .doc(userEmail)
            .get();

        if (userDoc.exists && userDoc.data()!.containsKey('role')) {
          prefs.setString(_userRoleKey, userDoc['role']);
        } else {
          await FirebaseFirestore.instance
              .collection(_userCollection)
              .doc(userEmail)
              .set({
            'email': userEmail,
            'role': _defaultRole,
          });
          prefs.setString(_userRoleKey, _defaultRole);
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      return null;
    }
  }

  // Email/Password Sign-In
  static Future<UserCredential?> signInWithEmail(
      String email, String password) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance.enableNetwork();
      await Future.delayed(const Duration(milliseconds: 500));

      final userDoc = await FirebaseFirestore.instance
          .collection(_userCollection)
          .doc(email)
          .get();

      if (userDoc.exists && userDoc.data()!.containsKey('role')) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(_userRoleKey, userDoc['role']);
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
