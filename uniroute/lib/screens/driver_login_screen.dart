import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/common_widgets.dart';
import '../utils/validators.dart';
import '../constants.dart';
import '../auth_services.dart';
import 'driver_home_screen.dart';
import 'forgot_password_screen.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _driverIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false;
  bool _keepSignedIn = false;

  String? _generalError;

  @override
  void initState() {
    super.initState();

    _checkAutoLogin();

    AuthServices.shouldKeepSignedIn().then((v) {
      if (mounted) setState(() => _keepSignedIn = v);
    });
  }

  Future<void> _checkAutoLogin() async {
    setState(() => _isLoading = true);

    try {
      final savedUser = await AuthServices.getSavedUser();
      final keep = await AuthServices.shouldKeepSignedIn();

      if (savedUser != null && keep) {
        // only allow drivers
        final roleName = _extractRoleName(savedUser);
        if (roleName == 'driver') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DriverHomeScreen(
                driver: savedUser, // ✅ pass full driver object
              ),
            ),
          );
          return;
        } else {
          debugPrint('Auto-login aborted: role is $roleName');
        }
      }
    } catch (e) {
      debugPrint("Auto-login failed: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _driverIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() => _generalError = null);
  }

  Future<void> _loginWithDriverId() async {
    _clearErrors();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final driverId = _driverIdController.text.trim();
    final password = _passwordController.text;

    try {
      final user = await AuthServices.signInWithIdentifier(
        driverId,
        password,
        _keepSignedIn,
      );

      if (user == null) {
        throw Exception('Login failed');
      }

      final roleName = _extractRoleName(user);
      if (roleName != 'driver') {
        throw Exception('Only drivers can log in here (role: $roleName)');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverHomeScreen(driver: user),
        ),
      );
    } catch (e) {
      setState(() {
        final raw = e.toString();
        _generalError = raw.replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToForgotPassword() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  Widget _buildErrorContainer(String? error) {
    if (error == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.errorColor.withOpacity(0.1),
        border: Border.all(
          color: AppConstants.errorColor.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppConstants.cornerRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppConstants.errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppConstants.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractRoleName(Map<String, dynamic>? user) {
    if (user == null) return '';
    final rn = user['role_name'] ?? user['role'];
    if (rn is String && rn.isNotEmpty) return rn.toLowerCase();
    if (user['roles'] is List && (user['roles'] as List).isNotEmpty) {
      final first = (user['roles'] as List)[0];
      if (first is Map && first['name'] != null) {
        return first['name'].toString().toLowerCase();
      }
      if (first is String) return first.toLowerCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AuthScaffold(
      title: "Driver Login",
      subtitle: "Enter your Driver ID or email and password",
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildErrorContainer(_generalError),

              // Driver ID / Email
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _driverIdController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter Driver ID or email'
                      : null,
                  onChanged: (_) => _clearErrors(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration:
                      buildInputDecoration('Driver ID or Email').copyWith(
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

              // Password
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  validator: AppValidators.password,
                  onFieldSubmitted: (_) => _loginWithDriverId(),
                  onChanged: (_) => _clearErrors(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: buildInputDecoration('Password').copyWith(
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () =>
                              setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                ),
              ),

              // Keep signed in
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Checkbox(
                      value: _keepSignedIn,
                      onChanged: _isLoading
                          ? null
                          : (v) => setState(() => _keepSignedIn = v ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: Colors.black,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () =>
                                setState(() => _keepSignedIn = !_keepSignedIn),
                        child: Text(
                          "Keep me signed in",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Continue Button
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginWithDriverId,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          "Continue",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              // Forgot Password
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _navigateToForgotPassword,
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
