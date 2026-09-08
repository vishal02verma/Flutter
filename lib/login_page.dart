import 'package:ayansh_bakery_my/forgote_pass.dart';
import 'package:ayansh_bakery_my/home_page.dart';
import 'package:ayansh_bakery_my/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  bool isPasswordVisible = false;
  bool loading = false;

  void loginUser() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (value) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email or password'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;
    final bool isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/img.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? size.width * 0.3 : (isTablet ? size.width * 0.15 : 20),
                vertical: 20,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: isDesktop ? 48 : 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildTextField(
                      controller: emailController,
                      hint: 'Enter your registered email',
                      label: 'Email',
                      icon: Icons.email_sharp,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: passwordController,
                      hint: 'Enter your Password',
                      label: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 40),
                    loading
                        ? const CircularProgressIndicator(color: Colors.red)
                        : SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade500,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupPage()),
                            );
                          },
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.red.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotePass()),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade500,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !isPasswordVisible : false,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        fillColor: Colors.white.withOpacity(0.9),
        filled: true,
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black54),
                onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
