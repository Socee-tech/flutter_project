import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersScreen extends StatefulWidget {
  final String supplierId;

  const OrdersScreen({super.key, required this.supplierId});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/flutter_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('supplierId', isEqualTo: widget.supplierId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final orders = snapshot.data?.docs ?? [];

              if (orders.isEmpty) {
                return const Center(
                  child: Text(
                    'No orders yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final doc = orders[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final orderId = doc.id;

                  return OrderCard(
                    orderId: orderId,
                    orderData: data,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}



class OrderCard extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String orderId;

  const OrderCard({
    super.key,
    required this.orderData,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final productName = orderData['productName'] ?? 'Unnamed';
    final retailerName = orderData['retailerName'] ?? 'Retailer';
    final status = orderData['status'] ?? 'pending';
    final productImage = orderData['productImage'];
    final timestamp = orderData['timestamp'] as Timestamp?;
    final formattedTime = _formatTimestamp(timestamp);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: productImage != null
                  ? Image.network(
                      productImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),

            // Info + Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By: $retailerName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: _buildStatusChip(status)),
                      DropdownButton<String>(
                        value: status,
                        icon: const Icon(Icons.arrow_drop_down),
                        style: const TextStyle(color: Colors.black),
                        underline: Container(height: 0),
                        onChanged: (String? newStatus) async {
                          if (newStatus != null && newStatus != status) {
                            await FirebaseFirestore.instance
                                .collection('orders')
                                .doc(orderId)
                                .update({'status': newStatus});
                          }
                        },
                        items: ['pending', 'shipped', 'cancelled']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value[0].toUpperCase() + value.substring(1),
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'shipped':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '—';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${date.year}/${date.month}/${date.day}";
  }
}

