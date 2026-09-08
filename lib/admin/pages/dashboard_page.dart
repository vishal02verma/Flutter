import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1200;
    final bool isTablet = size.width > 800 && size.width <= 1200;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 30 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard Overview",
                style: TextStyle(
                    fontSize: isDesktop ? 32 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown)),
            const SizedBox(height: 25),
            
            // Nested StreamBuilders to get all counts
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, prodSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                  builder: (context, catSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                      builder: (context, orderSnapshot) {
                        
                        if (orderSnapshot.hasError || prodSnapshot.hasError || catSnapshot.hasError) {
                          return const Center(child: Text("Error loading statistics", style: TextStyle(color: Colors.red)));
                        }

                        int totalOrders = 0;
                        int pendingOrders = 0;
                        double revenue = 0;

                        if (orderSnapshot.hasData) {
                          totalOrders = orderSnapshot.data!.docs.length;
                          for (var doc in orderSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            
                            // Status check
                            String status = data['status'] ?? 'Pending';
                            if (status == 'Pending') {
                              pendingOrders++;
                            }
                            
                            // Revenue calculation (only for Delivered orders)
                            if (status == 'Delivered') {
                              var amount = data['totalAmount'];
                              if (amount is num) {
                                revenue += amount.toDouble();
                              } else if (amount is String) {
                                revenue += double.tryParse(amount) ?? 0;
                              }
                            }
                          }
                        }

                        return GridView.count(
                          crossAxisCount: isDesktop ? 4 : (isTablet ? 2 : 1),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: isDesktop ? 1.6 : (isTablet ? 1.5 : 1.8),
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          children: [
                            _statCard(
                                "Total Revenue",
                                "₹${revenue.toStringAsFixed(0)}",
                                Icons.currency_rupee,
                                Colors.green),
                            _statCard(
                                "Total Orders",
                                totalOrders.toString(),
                                Icons.shopping_cart,
                                Colors.blue),
                            _statCard(
                                "Pending Orders",
                                pendingOrders.toString(),
                                Icons.pending_actions,
                                Colors.red),
                            _statCard(
                                "Total Products",
                                prodSnapshot.hasData
                                    ? prodSnapshot.data!.docs.length.toString()
                                    : "0",
                                Icons.cake,
                                Colors.purple),
                          ],
                        );
                      }
                    );
                  }
                );
              }
            ),
            
            const SizedBox(height: 40),
            Text("Order Status Summary",
                style: TextStyle(fontSize: isDesktop ? 26 : 22, fontWeight: FontWeight.bold, color: Colors.brown)),
            const SizedBox(height: 15),
            Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
              child: const Card(
                elevation: 2,
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.blue, size: 28),
                  title: Text("Tip for Admin", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Only orders marked as 'Delivered' are added to the Total Revenue calculation."),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: color),
            ),

            const SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  Text(title, 
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
