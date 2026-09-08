import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerManagementPage extends StatelessWidget {
  const CustomerManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Management"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}", 
                style: const TextStyle(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.brown));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No customers found", 
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          final customers = snapshot.data!.docs;

          if (isDesktop) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: DataTable(
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Avatar')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Email')),
                            DataColumn(label: Text('Details')),
                          ],
                          rows: customers.map((doc) {
                            final customer = doc.data() as Map<String, dynamic>;
                            return DataRow(cells: [
                              DataCell(_buildCustomerAvatar(customer['profileImage'], size: 40)),
                              DataCell(Text(customer['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(customer['email'] ?? 'No Email')),
                              DataCell(IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.brown),
                                onPressed: () => _showCustomerDetails(context, customer),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: customers.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final customer = customers[index].data() as Map<String, dynamic>;
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: _buildCustomerAvatar(customer['profileImage']),
                  title: Text(customer['name'] ?? 'Unknown User', 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(customer['email'] ?? 'No Email', 
                    style: TextStyle(color: Colors.grey.shade600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.brown),
                    onPressed: () => _showCustomerDetails(context, customer),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomerAvatar(dynamic imageData, {double size = 50}) {
    if (imageData == null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.brown,
        child: Icon(Icons.person, color: Colors.white, size: size * 0.6),
      );
    }

    if (imageData is String && imageData.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageData),
      );
    }

    if (imageData is Blob) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(imageData.bytes),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade300,
      child: Icon(Icons.person, color: Colors.grey, size: size * 0.6),
    );
  }

  void _showCustomerDetails(BuildContext context, Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Customer Details"),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildCustomerAvatar(customer['profileImage'], size: 80)),
              const SizedBox(height: 25),
              _detailRow("Name:", customer['name'] ?? "N/A"),
              _detailRow("Email:", customer['email'] ?? "N/A"),
              _detailRow("UID:", customer['uid'] ?? "N/A"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Close", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
