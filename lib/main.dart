import 'package:ayansh_bakery_my/about_page.dart';
import 'package:ayansh_bakery_my/admin/admin_login.dart';
import 'package:ayansh_bakery_my/category_page.dart';
import 'package:ayansh_bakery_my/home_page.dart';
import 'package:ayansh_bakery_my/login_page.dart';
import 'package:ayansh_bakery_my/profile_page.dart';
import 'package:ayansh_bakery_my/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayansh Bakery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}
