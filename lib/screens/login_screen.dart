
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shivam_super_market/common_import.dart';
import 'package:shivam_super_market/core/helper_function.dart';
import 'package:shivam_super_market/screens/dashboard_screen.dart';

import '../core/Textfield.dart';
import '../core/app_text_field.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController mEmailCont = TextEditingController();
  TextEditingController mPassCont = TextEditingController();
  FocusNode mEmailFocus = FocusNode();
  FocusNode mPassFocus = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    mEmailCont.dispose();
    mPassCont.dispose();
    mEmailFocus.dispose();
    mPassFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: mEmailCont.text, password: mPassCont.text);
      toast('Login Successful');
      await prefs.setBool('isLoggedIn', true);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    }catch(e){
      toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildMobileLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      decoration: BoxDecoration(
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor.withValues(alpha: 0.1),width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor,
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset("assets/logo.png", width: 80, fit: BoxFit.cover),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Field
          AppTextField(
            controller: mEmailCont,
            focus: mEmailFocus,
            textFieldType: TextFieldType.EMAIL,
            nextFocus: mPassFocus,
            decoration: defaultInputDecoration(
              context,
              label: 'Enter your email',
            ),
            isValidationRequired: true,
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: mPassCont,
            focus: mPassFocus,
            textFieldType: TextFieldType.OTHER,
            keyboardType: TextInputType.visiblePassword,
            decoration: defaultInputDecoration(
              context,
              label: 'Enter your password',
            ),
            onFieldSubmitted: (c) {
              _isLoading ? null : _handleLogin;
            },
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 24),

          // Login Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }


}
