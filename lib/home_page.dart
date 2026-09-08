import 'dart:async';
import 'package:ayansh_bakery_my/about_page.dart';
import 'package:ayansh_bakery_my/admin/admin_login.dart';
import 'package:ayansh_bakery_my/cart_page.dart';
import 'package:ayansh_bakery_my/category_page.dart';
import 'package:ayansh_bakery_my/login_page.dart';
import 'package:ayansh_bakery_my/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController pageController = PageController();
  int selected = 0;
  int currentPage = 0;

  late Stream<QuerySnapshot> _categoriesStream;
  late Stream<QuerySnapshot> _featuredProductsStream;
  late Stream<QuerySnapshot> _reviewsStream;

  final List<String> sliderImages = [
    "assets/images/slider.jpeg",
    "assets/images/slider2.jpeg",
  ];

  @override
  void initState() {
    super.initState();

    _categoriesStream = FirebaseFirestore.instance
        .collection('categories')
        .snapshots();

    _featuredProductsStream = FirebaseFirestore.instance
        .collection('products')
        .where('isFeatured', isEqualTo: true)
        .snapshots();

    _reviewsStream = FirebaseFirestore.instance
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots();

    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (pageController.hasClients) {
        currentPage++;
        if (currentPage >= sliderImages.length) currentPage = 0;
        pageController.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void changeselected(int index) {
    setState(() {
      selected = index;
    });
  }

  void _showReviewDialog(BuildContext context) {
    final TextEditingController reviewController = TextEditingController();

    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              title: const Text(
                "Write a Review",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "How was your experience?",
                      style: TextStyle(fontSize: 14),
                    ),

                    const SizedBox(height: 12),

                    // Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedRating = index + 1;
                            });
                          },

                          icon: Icon(
                            index < selectedRating
                                ? Icons.star
                                : Icons.star_border,
                          ),

                          color: Colors.orange,
                          iconSize: 32,
                        );
                      }),
                    ),

                    const SizedBox(height: 10),

                    // Review Text
                    TextField(
                      controller: reviewController,

                      maxLines: 4,

                      decoration: InputDecoration(
                        hintText: "Write your review...",
                        filled: true,
                        fillColor: Colors.orange.shade50,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please login to write a review"),
                        ),
                      );
                      return;
                    }

                    if (reviewController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please write your review"),
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('reviews')
                          .add({
                            'userId': user.uid,

                            'name': user.displayName ?? 'Customer',

                            'email': user.email ?? '',

                            'rating': selectedRating,

                            'review': reviewController.text.trim(),

                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      if (context.mounted) {
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Review submitted successfully ⭐"),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint("REVIEW ERROR: $e");

                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> openWhatsApp() async {
    final Uri whatsappUrl = Uri.parse(
      "https://wa.me/917524808395?text=%F0%9F%8E%82%20Hi%20Ayansh%20Bakery!%20I%E2%80%99m%20interested%20in%20ordering%20a%20custom%20cake.%20I%E2%80%99d%20like%20to%20discuss%20the%20design%2C%20flavor%2C%20size%2C%20and%20price.%20Please%20help%20me%20with%20my%20requirements.%20%F0%9F%98%8A",
    );
    if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch WhatsApp");
    }
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
          .doc(docId);

      final doc = await cartRef.get();

      if (doc.exists) {
        await cartRef.update({'quantity': FieldValue.increment(1)});
      } else {
        await cartRef.set({
          'id': docId,
          'name': product["name"] ?? "Item",
          'price': product["price"] ?? 0,
          'image': product["image"],
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Added to Cart"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding to cart: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider _getImageProvider(dynamic imageData) {
    if (imageData == null) return const AssetImage('assets/images/img.png');
    if (imageData is String && imageData.isNotEmpty) {
      if (imageData.startsWith('assets/')) return AssetImage(imageData);
      return NetworkImage(imageData);
    }
    if (imageData is Blob) return MemoryImage(imageData.bytes);
    return const AssetImage('assets/images/img.png');
  }

  Widget _buildImageWidget(dynamic imageData) {
    if (imageData == null) return const Icon(Icons.broken_image);
    if (imageData is String && imageData.isNotEmpty) {
      if (imageData.startsWith('assets/')) {
        return Image.asset(
          imageData,
          fit: BoxFit.cover,
          width: double.infinity,
        );
      }
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        width: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
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
    return const Icon(Icons.broken_image);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1024;
    final bool isTablet = size.width > 600 && size.width <= 1024;
    final double horizontalPadding = isDesktop
        ? size.width * 0.15
        : (isTablet ? 30 : 12);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.brown,
        centerTitle: false,
        title: Padding(
          padding: EdgeInsets.only(left: isDesktop ? size.width * 0.12 : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Ayansh',
                    style: TextStyle(
                      fontSize: 21,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'BAKERY',
                    style: TextStyle(fontSize: 13, color: Colors.redAccent),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            ),
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
          ),
          SizedBox(width: isDesktop ? size.width * 0.15 : 10),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: Colors.orange.shade50,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Welcome, ',
                      style: TextStyle(
                        color: Colors.brown.shade900,
                        fontSize: isDesktop ? 32 : 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${FirebaseAuth.instance.currentUser?.displayName ?? "User"} 👋',
                        style: TextStyle(
                          color: Colors.brown.shade900,
                          fontSize: isDesktop ? 28 : 20,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Freshly baked, just for you!',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                // Slider
                SizedBox(
                  height: isDesktop
                      ? 350
                      : (isTablet ? 250 : size.height * 0.22),
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: sliderImages.length,
                      onPageChanged: (index) =>
                          setState(() => currentPage = index),
                      itemBuilder: (context, index) =>
                          Image.asset(sliderImages[index], fit: BoxFit.fill),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Category',
                  style: TextStyle(
                    color: Colors.brown,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 15),
                // Horizontal Categories
                SizedBox(
                  height: 140,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _categoriesStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final categoriesList = snapshot.data!.docs;
                      if (categoriesList.isEmpty)
                        return const Center(child: Text("No Categories"));

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categoriesList.length,
                        itemBuilder: (context, index) {
                          final data =
                              categoriesList[index].data()
                                  as Map<String, dynamic>;
                          return Container(
                            key: ValueKey(categoriesList[index].id),
                            width: isDesktop ? 180 : 110,
                            margin: const EdgeInsets.only(right: 15),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(
                                        image: _getImageProvider(data["image"]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  data["name"] ?? "Category",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Popular Products',
                      style: TextStyle(
                        color: Colors.brown,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryPage(),
                        ),
                      ),
                      child: const Text(
                        "View all",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Featured Products
                SizedBox(
                  height: 280,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _featuredProductsStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final productsList = snapshot.data!.docs;
                      if (productsList.isEmpty)
                        return const Center(
                          child: Text("No Featured Products"),
                        );

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: productsList.length,
                        itemBuilder: (context, index) {
                          final data =
                              productsList[index].data()
                                  as Map<String, dynamic>;
                          final docId = productsList[index].id;
                          return Container(
                            key: ValueKey(docId),
                            width: isDesktop ? 250 : 200,
                            margin: const EdgeInsets.only(right: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.brown.shade50,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: _buildImageWidget(data["image"]),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  data["name"] ?? "Item",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₹${data["price"]}",
                                      style: const TextStyle(
                                        color: Colors.brown,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => addToCart(data, docId),
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Colors.brown,
                                        size: 34,
                                      ),
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
                const SizedBox(height: 40),
                // Custom Cake
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.orange.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Custom Cake",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Want a custom cake?",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              "Tell us your design and we will make it for you!",
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: openWhatsApp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Get Contact",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'assets/images/coustom cake.jpeg',
                          height: isDesktop ? 150 : 100,
                          width: isDesktop ? 150 : 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 400 ? 16 : 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.orange.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutPage(),
                            ),
                          );
                        },
                        child: Text(
                          "About Us",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 400
                                ? 18
                                : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Fresh, delicious, and beautifully crafted bakery treats "
                        "delivered with love. 🍰❤️",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 400
                              ? 13
                              : 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // ================= REVIEW SECTION =================
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading + Write Review
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "What Our Customers Say ❤️",
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 400
                                  ? 19
                                  : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ),

                        TextButton(
                          onPressed: () {
                            _showReviewDialog(context);
                          },
                          child: const Text(
                            "Write Review",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Firebase Reviews
                    StreamBuilder<QuerySnapshot>(
                      stream: _reviewsStream,

                      builder: (context, snapshot) {
                        // Loading
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 175,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                              ),
                            ),
                          );
                        }

                        // Error
                        if (snapshot.hasError) {
                          return const SizedBox(
                            height: 100,
                            child: Center(
                              child: Text(
                                "Unable to load reviews",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        // No Reviews
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                "No reviews yet.\nBe the first to review! ⭐",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          );
                        }

                        final reviews = snapshot.data!.docs;

                        // Reviews List
                        return SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: reviews.length,
                            itemBuilder: (context, index) {
                              final data =
                                  reviews[index].data() as Map<String, dynamic>;
                              final docId = reviews[index].id;

                              final String name = data['name'] ?? 'Customer';

                              final String reviewText = data['review'] ?? '';

                              final int rating = data['rating'] ?? 5;

                              return Container(
                                key: ValueKey(docId),
                                width: MediaQuery.of(context).size.width < 400
                                    ? MediaQuery.of(context).size.width * 0.78
                                    : 300,

                                margin: const EdgeInsets.only(right: 12),

                                padding: const EdgeInsets.all(16),

                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.shade100,
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Customer Name
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 21,
                                          backgroundColor:
                                              Colors.orange.shade100,

                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.orange,
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,

                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    // Rating
                                    Row(
                                      children: List.generate(5, (starIndex) {
                                        return Icon(
                                          starIndex < rating
                                              ? Icons.star
                                              : Icons.star_border,

                                          color: Colors.orange,
                                          size: 18,
                                        );
                                      }),
                                    ),

                                    const SizedBox(height: 8),

                                    // Review
                                    Expanded(
                                      child: Text(
                                        reviewText,

                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,

                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(isDesktop),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selected,
        onTap: (index) {
          changeselected(index);
          if (index == 1)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoryPage()),
            );
          if (index == 3)
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.brown,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'All Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'My Order',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isDesktop) {
    return Drawer(
      width: isDesktop ? 400 : null,
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/header.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Row(
                  children: const [
                    Icon(Icons.email_sharp, color: Colors.white70),
                    SizedBox(width: 8),
                    Text(
                      'Ayanshverma00000@gmail.com',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListTile(
            selected: selected == 0,
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              changeselected(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            selected: selected == 1,
            leading: const Icon(Icons.category),
            title: const Text("All Products"),
            onTap: () {
              changeselected(1);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPage()),
              );
            },
          ),
          ListTile(
            selected: selected == 3,
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              changeselected(3);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text("My Cart"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.admin_panel_settings,
              color: Colors.blueGrey,
            ),
            title: const Text("Admin Panel"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Log Out"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("No"),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        "Yes",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
