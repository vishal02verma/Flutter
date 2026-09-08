import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> updateQuantity(String productId, int change) async {
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart')
        .doc(productId);

    try {
      final doc = await cartRef.get();
      if (doc.exists) {
        int currentQuantity = doc.data()?['quantity'] ?? 0;
        int newQuantity = currentQuantity + change;

        if (newQuantity <= 0) {
          await cartRef.delete();
        } else {
          await cartRef.update({'quantity': newQuantity});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Widget _buildImageWidget(dynamic imageData) {
    if (imageData == null) return const Icon(Icons.broken_image);
    if (imageData is String && imageData.isNotEmpty) {
      return Image.network(
        imageData, 
        fit: BoxFit.cover, 
        width: 70, height: 70,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
      );
    }
    if (imageData is Blob) {
      return Image.memory(
        imageData.bytes, 
        fit: BoxFit.cover, 
        width: 70, height: 70,
      );
    }
    return const Icon(Icons.broken_image);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1024;
    final bool isTablet = size.width > 600 && size.width <= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/profile_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: user == null
            ? const Center(child: Text("Please login to see your cart"))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('cart')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.brown));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart_outlined,
                              size: 100, color: Colors.brown),
                          const SizedBox(height: 20),
                          const Text("Your cart is empty",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown),
                            child: const Text("Go Back",
                                style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    );
                  }

                  final cartItems = snapshot.data!.docs;

                  return Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 0 : (isTablet ? 30 : 10),
                          vertical: 10,
                        ),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final data =
                              cartItems[index].data() as Map<String, dynamic>;
                          final productId = cartItems[index].id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 5,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: _buildImageWidget(data["image"]),
                              ),
                              title: Text(data["name"] ?? "Item",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 18)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      "Total: ₹${(data["price"] ?? 0) * (data["quantity"] ?? 0)}",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.brown,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            updateQuantity(productId, -1),
                                        icon: const Icon(Icons.remove_circle_outline,
                                            color: Colors.red),
                                      ),
                                      const SizedBox(width: 8),
                                      Text("${data["quantity"]}",
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () =>
                                            updateQuantity(productId, 1),
                                        icon: const Icon(Icons.add_circle_outline,
                                            color: Colors.green),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              trailing: IconButton(
                                onPressed: () => updateQuantity(productId, -99),
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 30),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
