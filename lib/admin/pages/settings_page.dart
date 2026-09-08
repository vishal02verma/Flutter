import 'package:ayansh_bakery_my/admin/admin_login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ayansh_bakery_my/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('bakery').get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['bakeryName'] ?? '';
      _phoneController.text = data['contactPhone'] ?? '';
      _addressController.text = data['address'] ?? '';
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('settings').doc('bakery').set({
        'bakeryName': _nameController.text.trim(),
        'contactPhone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Settings saved!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bakery Settings"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? size.width * 0.25 : 20,
            vertical: 30,
          ),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Bakery Information", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                      const SizedBox(height: 25),
                      _buildField(_nameController, "Bakery Name", Icons.store_rounded),
                      const SizedBox(height: 20),
                      _buildField(_phoneController, "Contact Number", Icons.phone_rounded),
                      const SizedBox(height: 20),
                      _buildField(_addressController, "Address", Icons.location_on_rounded, maxLines: 3),
                      const SizedBox(height: 35),
                      _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: Colors.brown)) 
                        : SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown,
                                elevation: 5,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: _saveSettings, 
                              child: const Text("SAVE SETTINGS", 
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildLogoutButton(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.brown),
        prefixIcon: Icon(icon, color: Colors.brown),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.brown, width: 2)),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Card(
        color: Colors.red.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.red.shade200)),
        child: ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: const Text("Logout Admin", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AdminLoginPage()), (r) => false);
          },
        ),
      ),
    );
  }
}
