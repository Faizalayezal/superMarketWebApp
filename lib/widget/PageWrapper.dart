import 'package:flutter/material.dart';
import 'package:shivam_super_market/core/config.dart';
import 'package:shivam_super_market/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shivam_super_market/screens/login_screen.dart';

/// Wraps every screen with a consistent desktop page-header.
/// On mobile the AppBar is already handled by AppShell.
class PageWrapper extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;
  final EdgeInsets padding;

  const PageWrapper({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        MediaQuery.of(context).size.width >= kMobileBreak;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Desktop page header ───────────────────────────
        if (isDesktop)
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE0E8F0), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor)),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
                const SizedBox(width: 8),
                _AvatarMenu(),
              ],
            ),
          ),

        // ── Page content ──────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: padding,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _AvatarMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) async {
        if (value == 'logout') {
          await FirebaseAuth.instance.signOut();
          await prefs.setBool('isLoggedIn', false);
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
          );
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: const [
              Icon(Icons.logout_rounded, size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: secondaryColor,
          boxShadow: [
            BoxShadow(
                color: secondaryColor.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: const Center(
          child: Text('A',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ),
    );
  }
}