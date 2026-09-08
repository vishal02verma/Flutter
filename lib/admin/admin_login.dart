import 'package:ayansh_bakery_my/admin/admin_main_shell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _adminLogin() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // 1. Authenticate with FirebaseAuth
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // 2. Authorization: Check if user exists in 'admins' collection
        DocumentSnapshot adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(user.uid)
            .get();

        if (adminDoc.exists) {
          final data = adminDoc.data() as Map<String, dynamic>;
          final role = data['role'];
          final isActive = data['isActive'] ?? false;

          if (role == 'admin' && isActive == true) {
            // Success: Proceed to Admin Panel
            if (!mounted) return;
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const AdminMainShell()));
          } else {
            // Failure: Not an authorized admin
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            _showError("Access denied. Your admin account is inactive or role is invalid.");
          }
        } else {
          // Failure: Document does not exist in 'admins' collection
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          _showError("Access denied. You are not an administrator.");
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? "Login Failed");
    } catch (e) {
      if (!mounted) return;
      _showError("An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_rounded, size: 90, color: Colors.brown),
                const SizedBox(height: 25),
                const Text("Ayansh Bakery", 
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.brown)),
                const Text("Admin Dashboard", 
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Admin Email", 
                    labelStyle: const TextStyle(color: Colors.brown),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.brown, width: 2)),
                    prefixIcon: const Icon(Icons.email_rounded, color: Colors.brown),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passController,
                  obscureText: _obscure,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Colors.brown),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.brown, width: 2)),
                    prefixIcon: const Icon(Icons.lock_rounded, color: Colors.brown),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure), 
                      icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.brown)
                    ),
                  ),




                ),
                const SizedBox(height: 40),
                _loading 
                  ? const CircularProgressIndicator(color: Colors.brown) 
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown, 
                          foregroundColor: Colors.white,
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: _adminLogin, 
                        child: const Text("LOGIN TO DASHBOARD", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1))),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
