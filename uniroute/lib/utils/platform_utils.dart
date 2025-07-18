// lib/utils/platform_utils.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show TargetPlatform;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

bool get isAppleSignInAvailable {
  if (kIsWeb) return false;
  try {
    return defaultTargetPlatform == TargetPlatform.iOS || 
           defaultTargetPlatform == TargetPlatform.macOS;
  } catch (e) {
    return false;
  }
}