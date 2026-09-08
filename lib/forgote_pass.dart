import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotePass extends StatefulWidget {
  const ForgotePass({super.key});

  @override
  State<ForgotePass> createState() => _ForgotePassState();
}

class _ForgotePassState extends State<ForgotePass> {
  TextEditingController emailController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  bool loading = false;

  void resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email")));
      return;
    }

    setState(() => loading = true);
    try {
      await auth.sendPasswordResetEmail(email: emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your email for reset instructions'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Invalid email or something went wrong'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/img.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? size.width * 0.35 : 24),
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
                  const Icon(Icons.lock_reset_rounded, size: 80, color: Colors.brown),
                  const SizedBox(height: 20),
                  const Text("Forgot Password", 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
                  const SizedBox(height: 10),
                  const Text("We will send a reset link to your email", 
                    style: TextStyle(fontSize: 14, color: Colors.black87), textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  TextField(
                    controller: emailController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.brown),
                      fillColor: Colors.white.withOpacity(0.9),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.email_rounded, color: Colors.brown),
                    ),
                  ),
                  const SizedBox(height: 40),
                  loading
                      ? const CircularProgressIndicator(color: Colors.brown)
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: resetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade500,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            child: const Text('Reset Password', 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
