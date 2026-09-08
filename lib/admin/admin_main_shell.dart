import 'package:ayansh_bakery_my/admin/admin_login.dart';
import 'package:ayansh_bakery_my/admin/pages/about_management_page.dart';
import 'package:ayansh_bakery_my/admin/pages/category_management_page.dart';
import 'package:ayansh_bakery_my/admin/pages/customer_management_page.dart';
import 'package:ayansh_bakery_my/admin/pages/dashboard_page.dart';
import 'package:ayansh_bakery_my/admin/pages/order_management_page.dart';
import 'package:ayansh_bakery_my/admin/pages/product_management_page.dart';
import 'package:ayansh_bakery_my/admin/pages/settings_page.dart';
import 'package:ayansh_bakery_my/admin/responsive_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminMainShell extends StatefulWidget {
  const AdminMainShell({super.key});

  @override
  State<AdminMainShell> createState() => _AdminMainShellState();
}

class _AdminMainShellState extends State<AdminMainShell> {
  int _selectedIndex = 0;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAdminProtection();
  }

  Future<void> _checkAdminProtection() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      _kickOut();
      return;
    }

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        if (data['role'] == 'admin' && data['isActive'] == true) {
          if (mounted) setState(() => _isChecking = false);
          return;
        }
      }
      
      await FirebaseAuth.instance.signOut();
      _kickOut();
    } catch (e) {
      _kickOut();
    }
  }

  void _kickOut() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => const AdminLoginPage()), 
      (route) => false
    );
  }

  final List<Widget> _pages = [
    const DashboardPage(),
    const ProductManagementPage(),
    const OrderManagementPage(),
    const CategoryManagementPage(),
    const CustomerManagementPage(),
    const AboutManagementPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {

    if (_isChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.brown)),
      );
    }

    final bool isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: isDesktop ? null : AppBar(
        title: const Text("Ayansh Bakery Admin", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      drawer: isDesktop ? null : _sidebar(),
      body: Row(
        children: [
          if (isDesktop) 
            SizedBox(
              width: 250,
              child: _sidebar(),
            ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _sidebar() {
    return Drawer(
      elevation: 0,
      backgroundColor: Colors.brown.shade900,
      child: Column(
        children: [
          const DrawerHeader(
            child: Center(
              child: Icon(Icons.cake_rounded, color: Colors.white, size: 70),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _menuTile(0, "Dashboard", Icons.dashboard_rounded),
                _menuTile(1, "Products", Icons.shopping_bag_rounded),
                _menuTile(2, "Orders", Icons.list_alt_rounded),
                _menuTile(3, "Categories", Icons.category_rounded),
                _menuTile(4, "Customers", Icons.people_alt_rounded),
                _menuTile(5, "About Us", Icons.info_outline_rounded),
                _menuTile(6, "Settings", Icons.settings_rounded),
              ],
            ),
          ),
          const Divider(color: Colors.white24, indent: 20, endIndent: 20),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Log Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const AdminLoginPage()), 
                (r) => false
              );
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _menuTile(int index, String title, IconData icon) {
    final bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: isSelected,
        selectedTileColor: Colors.white.withOpacity(0.15),
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
        title: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: () {
          if (!Responsive.isDesktop(context)) Navigator.pop(context);
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
