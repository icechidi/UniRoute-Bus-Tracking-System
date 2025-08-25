// validators.dart
class AppValidators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email address is required';

    // Remove extra whitespace
    value = value.trim();

    // Check for basic email format
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address (e.g., user@example.com)';
    }

    // Check for common mistakes
    if (value.contains('..')) return 'Email cannot contain consecutive dots';
    if (value.startsWith('.') || value.endsWith('.')) {
      return 'Email cannot start or end with a dot';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialChar =
        RegExp(r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\;/~`]').hasMatch(value);

    List<String> missing = [];

    if (!hasUppercase) missing.add('uppercase letter');
    if (!hasLowercase) missing.add('lowercase letter');
    if (!hasNumber) missing.add('number');
    if (!hasSpecialChar) missing.add('special character');

    if (missing.isNotEmpty) {
      if (missing.length == 1) {
        return 'Password must contain at least one ${missing.first}';
      } else if (missing.length == 2) {
        return 'Password must contain at least one ${missing.join(' and one ')}';
      } else {
        final lastItem = missing.removeLast();
        return 'Password must contain at least one ${missing.join(', one ')}, and one $lastItem';
      }
    }

    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';

    value = value.trim();

    if (value.length < 2) return 'Name must be at least 2 characters long';
    if (value.length > 50) return 'Name must be less than 50 characters';

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';

    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (digitsOnly.length > 15) {
      return 'Phone number must be less than 15 digits';
    }

    // Check for valid phone format (allowing various formats)
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)\.]{10,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    return null;
  }

  static String? maxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.isEmpty) return 'URL is required';

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return 'Please enter a valid URL (e.g., https://example.com)';
      }
    } catch (e) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  static String? age(String? value) {
    if (value == null || value.isEmpty) return 'Age is required';

    final age = int.tryParse(value);
    if (age == null) return 'Please enter a valid age';

    if (age < 13) return 'You must be at least 13 years old';
    if (age > 120) return 'Please enter a valid age';

    return null;
  }
}
