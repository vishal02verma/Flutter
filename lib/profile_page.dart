import 'dart:typed_data';
import 'package:ayansh_bakery_my/about_page.dart';
import 'package:ayansh_bakery_my/edit_profile_page.dart';
import 'package:ayansh_bakery_my/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _selectAndSaveImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final Uint8List imageBytes = await image.readAsBytes();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'profileImage': Blob(imageBytes),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile image updated!"), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update image: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImage': FieldValue.delete(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile image removed")),
        );
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  Future<void> _handleLogout() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.brown, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Profile", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: user == null
            ? const Center(child: Text("Please Login"))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Error loading profile"));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.brown));

                  String name = user.displayName ?? "Bakery User";
                  dynamic profileImageData;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    name = data['name'] ?? name;
                    profileImageData = data['profileImage'];
                  }

                  return Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 15),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildProfileHeader(profileImageData, name, user.email),
                            const SizedBox(height: 35),
                            _buildStatsCard(),
                            const SizedBox(height: 30),
                            _buildMenuSection(context, name),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic imageData, String name, String? email) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.brown, shape: BoxShape.circle),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  backgroundImage: _getProfileImageProvider(imageData),
                  child: _isUploading ? const CircularProgressIndicator(color: Colors.brown) : null,
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') _selectAndSaveImage();
                    if (val == 'delete') _deleteImage();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.photo_library), SizedBox(width: 8), Text("Change Photo")])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text("Delete Photo")])),
                  ],
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.brown,
                    child: Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.brown)),
        const SizedBox(height: 4),
        Text(email ?? "No Email", style: TextStyle(fontSize: 16, color: Colors.brown.shade400)),
      ],
    );
  }

  ImageProvider _getProfileImageProvider(dynamic imageData) {
    if (imageData == null) return const AssetImage('assets/images/img.png');
    if (imageData is String && imageData.isNotEmpty) return NetworkImage(imageData);
    if (imageData is Blob) return MemoryImage(imageData.bytes);
    return const AssetImage('assets/images/img.png');
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(icon: Icons.shopping_cart_checkout_rounded, count: "0", label: "Orders"),
            _StatItem(icon: Icons.favorite_rounded, count: "0", label: "Wishlist"),
            _StatItem(icon: Icons.star_rounded, count: "0", label: "Reviews"),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, String currentName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10, bottom: 12),
          child: Text("MY ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2, fontSize: 13)),
        ),
        _MenuTile(icon: Icons.person_rounded, title: "Edit Profile", onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (ctx) => EditProfilePage(currentName: currentName)));
        }),
        _MenuTile(icon: Icons.location_on_rounded, title: "My Addresses", onTap: () {}),
        _MenuTile(icon: Icons.shopping_bag_rounded, title: "My Orders", onTap: () {}),
        _MenuTile(icon: Icons.favorite_rounded, title: "Wishlist", onTap: () {}),
        _MenuTile(icon: Icons.star_rounded, title: "My Reviews", onTap: () {}),
        _MenuTile(icon: Icons.notifications_rounded, title: "Notifications", onTap: () {}),
        const SizedBox(height: 25),
        const Padding(
          padding: EdgeInsets.only(left: 10, bottom: 12),
          child: Text("OTHERS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2, fontSize: 13)),
        ),
        _MenuTile(icon: Icons.privacy_tip_rounded, title: "Privacy Policy", onTap: () {}),
        _MenuTile(icon: Icons.info_rounded, title: "About Ayansh Bakery", onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AboutPage()));
        }),
        _MenuTile(icon: Icons.logout_rounded, title: "Logout", onTap: _handleLogout, isDestructive: true),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;

  const _StatItem({required this.icon, required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.brown, size: 32),
        const SizedBox(height: 8),
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuTile({required this.icon, required this.title, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: (isDestructive ? Colors.red : Colors.brown).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: isDestructive ? Colors.red : Colors.brown, size: 22),
        ),
        title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : Colors.black87, fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
