import 'package:ayansh_bakery_my/home_page.dart';
import 'package:ayansh_bakery_my/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  FirebaseAuth auth = FirebaseAuth.instance;
 void nextScreen()async{
   await Future.delayed(const Duration(seconds: 2));
   if(!mounted) return;
   if(auth.currentUser==null){
     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const LoginPage()),(value)=>false);
   }else{
     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=> const HomePage()),(value)=>false);
   }
 }
@override
  void initState() {
    nextScreen();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.orange.shade50,
        child: Center(
          child: Hero(
            tag: 'logo',
            child: Image.asset(
              'assets/images/logo.png',
              width: isDesktop ? 250 : 150,
              height: isDesktop ? 250 : 150,
              errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.cake_rounded, size: isDesktop ? 100 : 80, color: Colors.brown),
            ),
          ),
        ),
      )
    );
  }
}
