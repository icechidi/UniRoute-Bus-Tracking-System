// universal_app_bar.dart
import 'package:flutter/material.dart';

class UniversalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showProfile;
  final VoidCallback? onProfileTap;

  const UniversalAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.showProfile = true,
    this.onProfileTap, // ✅ Add this line
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          leading: (showBack || Navigator.canPop(context))
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack ?? () => Navigator.pop(context),
                )
              : null,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          actions: showProfile
              ? [
                  GestureDetector(
                    onTap: onProfileTap ?? () {},
                    child: const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: AssetImage(
                          'assets/images/profile_icon.png',
                        ),
                      ),
                    ),
                  ),
                ]
              : null,
        ),
        Container(height: 1, width: double.infinity, color: Colors.grey[300]),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
