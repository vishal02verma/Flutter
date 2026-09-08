import 'package:ayansh_bakery_my/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  bool loading = false;
  bool isPasswordVisible = false;

  void signupUser() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => loading = true);

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(nameController.text.trim());
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account successfully created")),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (value) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: isDesktop ? 48 : 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildField(nameController, 'Name', Icons.person),
                    const SizedBox(height: 20),
                    _buildField(emailController, 'Email', Icons.email),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 40),
                    loading 
                      ? const CircularProgressIndicator(color: Colors.red)
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: signupUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade500,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        const Text('Already registered!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Login',
                            style: TextStyle(color: Colors.red.shade500, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        prefixIcon: Icon(icon, color: Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: !isPasswordVisible,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        prefixIcon: const Icon(Icons.lock, color: Colors.black54),
        suffixIcon: IconButton(
          icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.black54),
          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
    );
  }
}
