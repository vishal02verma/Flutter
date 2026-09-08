import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  const EditProfilePage({super.key, required this.currentName});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  bool loading = false;
  Uint8List? selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => selectedImageBytes = bytes);
      }
    } catch (e) {
      debugPrint("Picker Error: $e");
    }
  }

  Future<void> updateProfile() async {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name cannot be empty")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Map<String, dynamic> updates = {'name': name};

        if (selectedImageBytes != null) {
          updates['profileImage'] = Blob(selectedImageBytes!);
        }

        await user.updateDisplayName(name);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updates, SetOptions(merge: true));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
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
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFFDF5E6),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? size.width * 0.25 : 20,
              vertical: 30,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImageSelector(),
                const SizedBox(height: 40),
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    labelStyle: const TextStyle(color: Colors.brown),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_rounded, color: Colors.brown),
                  ),
                ),
                const SizedBox(height: 50),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.brown, shape: BoxShape.circle),
          child: CircleAvatar(
            radius: 80,
            backgroundColor: Colors.white,
            backgroundImage: selectedImageBytes != null ? MemoryImage(selectedImageBytes!) : null,
            child: selectedImageBytes == null 
                ? const Icon(Icons.person_rounded, size: 80, color: Colors.brown) 
                : null,
          ),
        ),
        Positioned(
          bottom: 5,
          right: 5,
          child: GestureDetector(
            onTap: pickImage,
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.brown,
              child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    if (loading) return const CircularProgressIndicator(color: Colors.brown);
    
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: updateProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown,
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("SAVE CHANGES", 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
      ),
    );
  }
}
