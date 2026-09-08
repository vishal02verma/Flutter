import 'package:ayansh_bakery_my/cart_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  
  /// BUG FIX: Safe Image Widget (Handles URL, Assets, and Firestore Blobs)
  Widget _buildImageWidget(dynamic imageData) {
    if (imageData == null) return const Center(child: Icon(Icons.broken_image));
    if (imageData is String && imageData.isNotEmpty) {
      if (imageData.startsWith('assets/')) {
        return Image.asset(imageData, fit: BoxFit.cover, width: double.infinity);
      }
      return Image.network(
        imageData, 
        fit: BoxFit.cover, 
        width: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image)),
      );
    }
    if (imageData is Blob) {
      return Image.memory(
        imageData.bytes, 
        fit: BoxFit.cover, 
        width: double.infinity,
        gaplessPlayback: true,
      );
    }
    return const Center(child: Icon(Icons.broken_image));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Products", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => const CartPage())),
            icon: const Icon(Icons.shopping_cart),
          )
        ],
      ),
      body: Container(
        color: Colors.orange.shade50,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No products available"));
            }

            final products = snapshot.data!.docs;
            final size = MediaQuery.of(context).size;
            final int crossAxisCount =
                size.width > 900 ? 4 : (size.width > 600 ? 3 : 2);

            return GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final productData =
                    products[index].data() as Map<String, dynamic>;
                final docId = products[index].id;

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05), blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _buildImageWidget(productData["image"]), // FIX: Used safe image widget
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(productData["name"] ?? "Item",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("₹${productData["price"]}",
                              style: const TextStyle(
                                  color: Colors.brown,
                                  fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () => addToCart(productData, docId), // FIX: Passed docId
                            child: const Icon(Icons.add_circle,
                                color: Colors.brown, size: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> addToCart(Map<String, dynamic> product, String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add items to cart")),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(docId); // Use document ID for reliability

      final doc = await cartRef.get();

      if (doc.exists) {
        await cartRef.update({
          'quantity': FieldValue.increment(1),
        });
      } else {
        await cartRef.set({
          'id': docId,
          'name': product["name"] ?? "Item",
          'price': product["price"] ?? 0,
          'image': product["image"], // Supports both String and Blob
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to Cart")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding to cart: $e")),
      );
    }
  }
}
