// role_selector_screen.dart
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
    setState(() => _languageSelected = true);
    await _animationController.reverse();

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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/bus_logo.png',
                    width: 180,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.directions_bus,
                      size: 180,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  RoleButton(
                    label: 'student',
                    icon: LucideIcons.graduationCap,
                    role: 'student',
                    selectedRole: _selectedRole,
                    onTap: () => _selectRole('student'),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  RoleButton(
                    label: 'driver',
                    icon: LucideIcons.bus,
                    role: 'driver',
                    selectedRole: _selectedRole,
                    onTap: () => _selectRole('driver'),
                  ),
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 12),
                  Text(
                    'by_continuing_you_agree'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_languageSelected)
            LanguageSelectionModal(
              slideAnimation: _slideAnimation,
              opacityAnimation: _opacityAnimation,
              onLanguageSelected: (locale) => _setLanguage(locale),
            ),
        ],
      ),
    );
  }
}

class RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String role;
  final String? selectedRole;
  final VoidCallback onTap;

  const RoleButton({
    super.key,
    required this.label,
    required this.icon,
    required this.role,
    required this.selectedRole,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedRole == role;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF8C8C8C) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(4, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 28,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageSelectionModal extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final Animation<double> opacityAnimation;
  final Function(Locale) onLanguageSelected;

  const LanguageSelectionModal({
    super.key,
    required this.slideAnimation,
    required this.opacityAnimation,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: opacityAnimation,
              child: Container(
                padding: const EdgeInsets.only(top: 24, bottom: 32),
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
                    _buildLanguageOption('🇹🇷', 'turkish', const Locale('tr')),
                    const Divider(height: 1, thickness: 1),
                    _buildLanguageOption('🇬🇧', 'english', const Locale('en')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String language, Locale locale) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onLanguageSelected(locale),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
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
}
