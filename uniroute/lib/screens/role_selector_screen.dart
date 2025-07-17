import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
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
  bool _isNavigating = false;

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initLanguageCheck();
    _loadSelectedRole();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _initLanguageCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('selected_language_code');

    if (savedLanguageCode != null) {
      if (!mounted) return;
      await context.setLocale(Locale(savedLanguageCode));
      setState(() => _languageSelected = true);
    } else {
      await Future.delayed(Duration.zero);
      if (!mounted) return;
      _animationController.forward(); // Slide up
    }
  }

  Future<void> _setLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language_code', locale.languageCode);

    if (!mounted) return;
    await context.setLocale(locale);
    setState(() => _languageSelected = true);
    await _animationController.reverse(); // Slide down

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale.languageCode == 'tr'
              ? 'Dil Türkçe olarak ayarlandı'
              : 'Language set to English',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _selectRole(String role) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRole = role;
    });
  }

  Future<void> _loadSelectedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRole = prefs.getString('userRole');
    if (savedRole != null) {
      setState(() => _selectedRole = savedRole);
    }
  }

  Future<void> _saveRoleAndContinue() async {
    if (_selectedRole == null || _isNavigating) return;

    setState(() {
      _isNavigating = true;
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', _selectedRole!);

    if (!mounted) return;

    Widget screen = _selectedRole == 'student'
        ? const StudentLoginScreen()
        : const DriverLoginScreen();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isNavigating = false;
    });
  }

  Widget _roleButton(String label, IconData icon, String role) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => _selectRole(role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[300] : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: Colors.black87),
          ],
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
                  Semantics(
                    label: 'Bus app logo',
                    child: Image.asset(
                      'assets/images/bus_logo.png',
                      width: 200,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.directions_bus,
                            size: 200, color: Colors.grey);
                      },
                    ),
                  ),
                  const SizedBox(height: 60),
                  _roleButton('student', Icons.school, 'student'),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1),
                  const SizedBox(height: 20),
                  _roleButton('driver', Icons.directions_bus, 'driver'),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              "continue".tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white, // ✅ white text color
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔻 Slide-Up Language Modal
          if (!_languageSelected)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha((0.6 * 255).toInt()),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 16),
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Text("🇹🇷",
                                style: TextStyle(fontSize: 24)),
                            title: Text('turkish'.tr()),
                            onTap: () => _setLanguage(const Locale('tr')),
                          ),
                          ListTile(
                            leading: const Text("🇬🇧",
                                style: TextStyle(fontSize: 24)),
                            title: Text('english'.tr()),
                            onTap: () => _setLanguage(const Locale('en')),
                          ),
                        ],
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
