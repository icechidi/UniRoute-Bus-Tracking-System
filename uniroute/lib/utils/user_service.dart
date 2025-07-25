import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // User data model matching your complete profile structure
  static const String _usersCollection = 'users';

  // Create or update user profile (matching your ProfileData structure)
  static Future<bool> createOrUpdateUserProfile({
    required String
        email, // Using email as document ID like in your complete profile
    String? firstName,
    String? lastName,
    String? username,
    String? country,
    String? studentId,
    String? phone,
    String? photoURL,
    String? displayName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userDoc = _firestore.collection(_usersCollection).doc(email);

      final userData = {
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'username': username ?? '',
        'country': country ?? '',
        'student_id': studentId ?? '',
        'phone': phone ?? '',
        'email': email,
        'photo_url': photoURL ?? '',
        'display_name': displayName ?? '',
        'updated_at': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      // Check if user exists
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        // Update existing user (don't overwrite created_at and other completion data)
        userData.remove('email_status');
        userData.remove('account_status');
        userData.remove('profile_completed_at');
        await userDoc.update(userData);
      } else {
        // Create new user
        userData['created_at'] = FieldValue.serverTimestamp();
        userData['email_status'] = 'verified';
        userData['account_status'] = 'incomplete';
        await userDoc.set(userData);
      }

      return true;
    } catch (e) {
      debugPrint("Error creating/updating user profile: $e");
      return false;
    }
  }

  // Get user profile using email as document ID
  static Future<Map<String, dynamic>?> getUserProfile([String? email]) async {
    try {
      final userEmail = email ?? _auth.currentUser?.email;
      if (userEmail == null) return null;

      final docSnapshot =
          await _firestore.collection(_usersCollection).doc(userEmail).get();

      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint("Error getting user profile: $e");
      return null;
    }
  }

  // Get user profile stream for real-time updates
  static Stream<Map<String, dynamic>?> getUserProfileStream([String? email]) {
    try {
      final userEmail = email ?? _auth.currentUser?.email;
      if (userEmail == null) {
        return Stream.value(null);
      }

      return _firestore
          .collection(_usersCollection)
          .doc(userEmail)
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists) {
          return snapshot.data();
        }
        return null;
      });
    } catch (e) {
      debugPrint("Error getting user profile stream: $e");
      return Stream.value(null);
    }
  }

  // Update specific user field
  static Future<bool> updateUserField(String field, dynamic value) async {
    try {
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) return false;

      await _firestore.collection(_usersCollection).doc(userEmail).update({
        field: value,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Error updating user field: $e");
      return false;
    }
  }

  // Update multiple user fields
  static Future<bool> updateUserFields(Map<String, dynamic> fields) async {
    try {
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) return false;

      fields['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(_usersCollection)
          .doc(userEmail)
          .update(fields);

      return true;
    } catch (e) {
      debugPrint("Error updating user fields: $e");
      return false;
    }
  }

  // Verify user owns the profile before deletion
  static Future<bool> verifyUserOwnership() async {
    try {
      final user = _auth.currentUser;
      final userEmail = user?.email;

      if (userEmail == null) return false;

      final docSnapshot =
          await _firestore.collection(_usersCollection).doc(userEmail).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        // Verify the email in the document matches the authenticated user
        return data?['email'] == userEmail;
      }

      return false;
    } catch (e) {
      debugPrint("Error verifying user ownership: $e");
      return false;
    }
  }

  // Delete user profile with ownership verification
  static Future<bool> deleteUserProfile() async {
    try {
      final user = _auth.currentUser;
      final userEmail = user?.email;

      if (userEmail == null) {
        debugPrint("No authenticated user found");
        return false;
      }

      // Verify ownership before deletion
      if (!await verifyUserOwnership()) {
        debugPrint("User ownership verification failed");
        return false;
      }

      debugPrint("Attempting to delete profile for user: $userEmail");

      // Delete the specific user document using email as document ID
      await _firestore.collection(_usersCollection).doc(userEmail).delete();

      debugPrint("Successfully deleted profile for user: $userEmail");
      return true;
    } catch (e) {
      debugPrint("Error deleting user profile: $e");
      return false;
    }
  }

  // Check if username is available (excluding current user)
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final currentUserEmail = _auth.currentUser?.email;

      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('username', isEqualTo: username.toLowerCase().trim())
          .limit(2) // Get up to 2 to check if any other user has it
          .get();

      // If no documents found, username is available
      if (querySnapshot.docs.isEmpty) return true;

      // If only one document and it's the current user, username is available
      if (querySnapshot.docs.length == 1 &&
          querySnapshot.docs.first.id == currentUserEmail) {
        return true;
      }

      // Otherwise, username is taken
      return false;
    } catch (e) {
      debugPrint("Error checking username availability: $e");
      return false;
    }
  }

  // Check if student ID is available (excluding current user)
  static Future<bool> isStudentIdAvailable(String studentId) async {
    try {
      final currentUserEmail = _auth.currentUser?.email;

      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('student_id', isEqualTo: studentId.trim())
          .limit(2)
          .get();

      // If no documents found, student ID is available
      if (querySnapshot.docs.isEmpty) return true;

      // If only one document and it's the current user, student ID is available
      if (querySnapshot.docs.length == 1 &&
          querySnapshot.docs.first.id == currentUserEmail) {
        return true;
      }

      // Otherwise, student ID is taken
      return false;
    } catch (e) {
      debugPrint("Error checking student ID availability: $e");
      return false;
    }
  }

  // Get current user's last username change
  static Future<DateTime?> getLastUsernameChange() async {
    try {
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) return null;

      final docSnapshot =
          await _firestore.collection(_usersCollection).doc(userEmail).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final timestamp = data?['last_username_change'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      debugPrint("Error getting last username change: $e");
      return null;
    }
  }

  // Update username with timestamp
  static Future<bool> updateUsername(String newUsername) async {
    try {
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) return false;

      final cleanUsername = newUsername.toLowerCase().trim();

      // Check if username is available
      if (!await isUsernameAvailable(cleanUsername)) {
        return false;
      }

      await _firestore.collection(_usersCollection).doc(userEmail).update({
        'username': cleanUsername,
        'last_username_change': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Error updating username: $e");
      return false;
    }
  }

  // Get full name from first_name and last_name
  static String getFullName(Map<String, dynamic>? userData) {
    if (userData == null) return '';

    final firstName = userData['first_name'] ?? '';
    final lastName = userData['last_name'] ?? '';

    return '$firstName $lastName'.trim();
  }

  // Update profile photo URL
  static Future<bool> updateProfilePhoto(String photoURL) async {
    try {
      final userEmail = _auth.currentUser?.email;
      if (userEmail == null) return false;

      await _firestore.collection(_usersCollection).doc(userEmail).update({
        'photo_url': photoURL,
        'updated_at': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Error updating profile photo: $e");
      return false;
    }
  }

  // Check if profile is complete
  static bool isProfileComplete(Map<String, dynamic>? userData) {
    if (userData == null) return false;

    return userData['account_status'] == 'complete' &&
        (userData['first_name'] ?? '').isNotEmpty &&
        (userData['last_name'] ?? '').isNotEmpty &&
        (userData['username'] ?? '').isNotEmpty &&
        (userData['country'] ?? '').isNotEmpty &&
        (userData['student_id'] ?? '').isNotEmpty;
  }
}
