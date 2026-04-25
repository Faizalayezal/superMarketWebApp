import 'package:flutter/material.dart';
import 'package:shivam_super_market/screens/dashboard_screen.dart';
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
    init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ClipOval(
          child: Image.asset(
            "assets/logo.png",
            width: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  void init() async{
    bool isLogin=await prefs.getBool('isLoggedIn')??false;
    if(isLogin){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen()));
    }else{
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

}
