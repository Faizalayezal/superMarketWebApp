import 'package:flutter/material.dart';
import 'package:shivam_super_market/screens/AppShell.dart';
import 'package:shivam_super_market/screens/dashboard_screen.dart';
import 'package:shivam_super_market/screens/login_screen.dart';
import '../main.dart';

import 'package:flutter/material.dart';
import 'package:shivam_super_market/screens/login_screen.dart';
import '../main.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final bool isLogin = prefs.getBool('isLoggedIn') ?? false;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLogin ? const AppShell() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2137),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                    color: const Color(0xFFFE6B01).withOpacity(0.6), width: 2),
              ),
              child: ClipOval(
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'SHIVAM SUPER MARKET',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFFFE6B01)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}