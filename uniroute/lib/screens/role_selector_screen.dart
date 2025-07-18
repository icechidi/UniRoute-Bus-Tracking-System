import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'student_login_screen.dart';
import 'driver_login_screen.dart';

class RoleSelectorScreen extends StatefulWidget {
  const RoleSelectorScreen({super.key});

  @override
  State<RoleSelectorScreen> createState() => _RoleSelectorScreenState();
}

class _RoleSelectorScreenState extends State<RoleSelectorScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  bool _languageSelected = false;
  bool _isLoading = false;
  late SharedPreferences _prefs;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initPreferences();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    final savedLanguage = _prefs.getString('selected_language_code');
    final savedRole = _prefs.getString('userRole');

    if (savedLanguage != null) {
      if (!mounted) return;
      await context.setLocale(Locale(savedLanguage));
      setState(() => _languageSelected = true);
    } else {
      _animationController.forward();
    }

    if (savedRole != null) {
      setState(() => _selectedRole = savedRole);
    }
  }

  Future<void> _setLanguage(Locale locale) async {
    setState(() {
      _languageSelected = true; // Immediate UI update
    });

    await _animationController.reverse();

    // Perform async operations after animation completes
    await Future.wait([
      _prefs.setString('selected_language_code', locale.languageCode),
      if (mounted) context.setLocale(locale),
    ]);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale.languageCode == 'tr'
              ? 'language_set_tr'.tr()
              : 'language_set_en'.tr(),
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _selectRole(String role) {
    HapticFeedback.selectionClick();
    setState(() => _selectedRole = role);
  }

  Future<void> _saveRoleAndContinue() async {
    if (_selectedRole == null || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _prefs.setString('userRole', _selectedRole!);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _selectedRole == 'student'
              ? const StudentLoginScreen()
              : const DriverLoginScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRoleButton(String label, IconData icon, String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.black.withAlpha((0.05 * 255).toInt())
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: Colors.black, width: 2)
              : Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.tr(),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.black87,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: isSelected ? Colors.black : Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String language, Locale locale) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _setLanguage(locale),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Text(
                flag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 16),
              Text(
                language.tr(),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/bus_logo.png',
                    width: 200,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.directions_bus,
                      size: 200,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildRoleButton(
                      'student', LucideIcons.graduationCap, 'student'),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1),
                  const SizedBox(height: 20),
                  _buildRoleButton('driver', LucideIcons.bus, 'driver'),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedRole == null || _isLoading
                          ? null
                          : _saveRoleAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            )
                          : Text(
                              "continue".tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_languageSelected)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha((0.6 * 255).toInt()),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _opacityAnimation,
                      child: Container(
                        padding: const EdgeInsets.only(
                          top: 24,
                          left: 16,
                          right: 16,
                          bottom: 32,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'select_language'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildLanguageOption(
                                '🇹🇷', 'turkish', const Locale('tr')),
                            const Divider(height: 1, thickness: 1),
                            _buildLanguageOption(
                                '🇬🇧', 'english', const Locale('en')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
