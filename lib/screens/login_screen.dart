
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shivam_super_market/common_import.dart';
import 'package:shivam_super_market/core/helper_function.dart';
import 'package:shivam_super_market/screens/AppShell.dart';
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
  final TextEditingController _emailCont = TextEditingController();
  final TextEditingController _passCont  = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus  = FocusNode();
  bool _isLoading = false;
  bool _obscure   = true;

  @override
  void dispose() {
    _emailCont.dispose();
    _passCont.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCont.text.trim(),
        password: _passCont.text.trim(),
      );
      toast('Login Successful');
      await prefs.setBool('isLoggedIn', true);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } catch (e) {
      toast(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sidebarColor,
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        return isWide ? _buildWideLayout() : _buildMobileLayout();
      }),
    );
  }

  // ── Wide (web/tablet) layout – card centered ─────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left decorative panel
        Expanded(
          child: Container(
            color: primaryColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: secondaryColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: secondaryColor.withOpacity(0.4),
                        blurRadius: 30,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  superMarketTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  billAddress,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        // Right form panel
        Expanded(
          child: Container(
            color: const Color(0xFFEFF4F8),
            child: Center(
              child: SizedBox(
                width: 380,
                child: _loginCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile layout ─────────────────────────────────────────
  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: secondaryColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.4),
                    blurRadius: 20,
                  )
                ],
              ),
              child: ClipOval(
                child: Image.asset('assets/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              superMarketTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 40),
            _loginCard(),
          ],
        ),
      ),
    );
  }

  Widget _loginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text('Sign in to continue',
                style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 28),
            // Email
            AppTextField(
              controller: _emailCont,
              focus: _emailFocus,
              nextFocus: _passFocus,
              textFieldType: TextFieldType.EMAIL,
              decoration: defaultInputDecoration(context, label: 'Email'),
            ),
            const SizedBox(height: 16),
            // Password
            AppTextField(
              controller: _passCont,
              focus: _passFocus,
              textFieldType: TextFieldType.PASSWORD,
              isPassword: _obscure,
              decoration: defaultInputDecoration(context, label: 'Password')
                  .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Text('Login',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}