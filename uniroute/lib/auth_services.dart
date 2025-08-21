// lib/services/auth_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthServices {
  // Keys
  static const String _keepSignedInKey = 'keep_signed_in';
  static const String _authTokenKey = 'auth_token'; // in secure storage
  static const String _authEmailKey = 'auth_email';
  static const String _authUserKey = 'auth_user'; // user JSON in prefs

  // 👇 Replace with your private IP and port
  // Example: backend machine IP = 192.168.1.50
  static const String loginUrl = 'http://172.55.4.160:3000/api/auth/login';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<Map<String, dynamic>?> signInWithIdentifier(
      String identifierOrEmail, String password, bool keepSignedIn) async {
    try {
      final bool looksLikeEmail = identifierOrEmail.contains('@');

      final body = looksLikeEmail
          ? {'email': identifierOrEmail, 'password': password}
          : {'identifier': identifierOrEmail, 'password': password};

      final resp = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final respBody = json.decode(resp.body);

      if (resp.statusCode != 200) {
        final msg = (respBody is Map &&
                (respBody['message'] ?? respBody['error']) != null)
            ? (respBody['message'] ?? respBody['error'])
            : 'Login failed';
        throw Exception(msg);
      }

      final user = (respBody is Map && respBody['user'] != null)
          ? Map<String, dynamic>.from(respBody['user'])
          : null;

      final token = (respBody is Map &&
              (respBody['token'] ?? respBody['access_token']) != null)
          ? (respBody['token'] ?? respBody['access_token']) as String
          : null;

      await _saveAuthData(
          token, user, looksLikeEmail ? identifierOrEmail : null, keepSignedIn);

      return user;
    } catch (e) {
      debugPrint('signInWithIdentifier error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> signInWithEmail(
      String email, String password, bool keepSignedIn) {
    return signInWithIdentifier(email, password, keepSignedIn);
  }

  static Future<void> signOut({String? logoutUrl}) async {
    try {
      if (logoutUrl != null) {
        try {
          await http.post(Uri.parse(logoutUrl));
        } catch (e) {
          debugPrint('Server logout failed: $e');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keepSignedInKey);
      await prefs.remove(_authEmailKey);
      await prefs.remove(_authUserKey);
      await _secureStorage.delete(key: _authTokenKey);
    } catch (e) {
      debugPrint('signOut error: $e');
    }
  }

  static Future<void> _saveAuthData(String? token, Map<String, dynamic>? user,
      String? email, bool keepSignedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepSignedInKey, keepSignedIn);

    if (keepSignedIn) {
      if (email != null) await prefs.setString(_authEmailKey, email);
      if (user != null) {
        try {
          await prefs.setString(_authUserKey, json.encode(user));
        } catch (e) {
          debugPrint('Failed to encode user: $e');
        }
      }
      if (token != null) {
        await _secureStorage.write(key: _authTokenKey, value: token);
      } else {
        await _secureStorage.delete(key: _authTokenKey);
        debugPrint(
            'Warning: no token returned from server; persistent auth for API calls will not be available.');
      }
    } else {
      await prefs.remove(_authEmailKey);
      await prefs.remove(_authUserKey);
      await _secureStorage.delete(key: _authTokenKey);
    }
  }

  static Future<bool> shouldKeepSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepSignedInKey) ?? false;
  }

  static Future<String?> getStoredToken() async {
    return _secureStorage.read(key: _authTokenKey);
  }

  static Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authEmailKey);
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_authUserKey);
    if (jsonStr == null) return null;
    try {
      return Map<String, dynamic>.from(json.decode(jsonStr));
    } catch (e) {
      debugPrint('Failed to decode stored user: $e');
      return null;
    }
  }

  static Future<Map<String, String>> authHeaders() async {
    final token = await getStoredToken();
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
