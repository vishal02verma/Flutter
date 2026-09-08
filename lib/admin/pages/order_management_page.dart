import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderManagementPage extends StatelessWidget {
  const OrderManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Management"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.brown));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found", style: TextStyle(fontSize: 16)));
          }

          final orders = snapshot.data!.docs;

          if (isDesktop) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: DataTable(
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: orders.map((doc) {
                            final order = doc.data() as Map<String, dynamic>;
                            final orderId = doc.id;
                            return DataRow(cells: [
                              DataCell(Text("#${orderId.substring(0, 5)}...")),
                              DataCell(Text(order['customerName'] ?? "Unknown")),
                              DataCell(Text("₹${order['totalAmount']}")),
                              DataCell(_statusChip(order['status'] ?? 'Pending')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.brown),
                                    onPressed: () => _showOrderDetailsDialog(context, order, orderId),
                                  ),
                                  _statusActionMenu(context, orderId),
                                ],
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
            itemCount: orders.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final status = order['status'] ?? 'Pending';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text("Order #$orderId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text("Customer: ${order['customerName'] ?? 'Unknown'}\nTotal: ₹${order['totalAmount']}",
                        style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
                  ),
                  trailing: _statusChip(status),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Items Ordered:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown)),
                          const SizedBox(height: 12),
                          ...(order['items'] as List? ?? []).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("${item['name']}", style: const TextStyle(fontSize: 15)),
                                  Text("x ${item['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                          const Divider(height: 30),
                          const Text("Update Status:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10, runSpacing: 10,
                            children: [
                              _updateButton(context, orderId, "Confirmed", Colors.blue),
                              _updateButton(context, orderId, "Preparing", Colors.orange),
                              _updateButton(context, orderId, "Out for Delivery", Colors.purple),
                              _updateButton(context, orderId, "Delivered", Colors.green),
                              _updateButton(context, orderId, "Cancelled", Colors.red),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.grey;
    if (status == 'Confirmed') color = Colors.blue;
    if (status == 'Preparing') color = Colors.orange;
    if (status == 'Out for Delivery') color = Colors.purple;
    if (status == 'Delivered') color = Colors.green;
    if (status == 'Cancelled') color = Colors.red;

    return Chip(
      padding: EdgeInsets.zero,
      label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: color,
    );
  }

  Widget _updateButton(BuildContext context, String orderId, String newStatus, Color color) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () async => await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus}),
      child: Text(newStatus, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),

    );
  }

  Widget _statusActionMenu(BuildContext context, String orderId) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.edit_notifications_rounded, color: Colors.blue),
      tooltip: "Change Status",
      onSelected: (val) async => await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': val}),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: "Confirmed", child: Text("Confirm")),
        const PopupMenuItem(value: "Preparing", child: Text("Prepare")),
        const PopupMenuItem(value: "Out for Delivery", child: Text("Dispatch")),
        const PopupMenuItem(value: "Delivered", child: Text("Deliver")),
        const PopupMenuItem(value: "Cancelled", child: Text("Cancel")),
      ],
    );
  }

  void _showOrderDetailsDialog(BuildContext context, Map<String, dynamic> order, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Order Details #$id", style: const TextStyle(color: Colors.brown)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Customer: ${order['customerName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(height: 30),
              ...(order['items'] as List? ?? []).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(item['name']), Text("x${item['quantity']}")],
                ),
              )).toList(),
              const Divider(height: 30),
              Text("Total Amount: ₹${order['totalAmount']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))],
      ),
    );
  }
}
