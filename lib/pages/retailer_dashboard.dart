import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_su_re/utils/helpers.dart';


// ✅ Stateful Supplier List Screen
class RetailerDashboard extends StatefulWidget {
  const RetailerDashboard({super.key});

  @override
  _RetailerDashboardState createState() => _RetailerDashboardState();
}

class _RetailerDashboardState extends State<RetailerDashboard> {
  Set<String> _followedSuppliers = {};

  @override
  void initState() {
    super.initState();
    _loadFollowedSuppliers();
  }

  Future<void> _loadFollowedSuppliers() async {
    final retailerId = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance
        .collection('followers')
        .where('followers', arrayContains: retailerId)
        .get();

    setState(() {
      _followedSuppliers = snapshot.docs.map((doc) => doc.id).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
              // Show success message
              showSuccess(context, 'Logged out successfully');
            },
          ),
        ],
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
      StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'supplier')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final suppliers = snapshot.data!.docs;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              var supplier = suppliers[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupplierProductsScreen(
                          supplierId: supplier.id,
                          supplierName: supplier['name'],
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Image.network(
                            "https://picsum.photos/seed/${supplier.id}/200/200",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              supplier['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _followedSuppliers.contains(supplier.id)
                                ? ElevatedButton(
                                    onPressed: () {},
                                    child: const Text("Following"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      followSupplier(
                                        supplier.id,
                                        FirebaseAuth.instance.currentUser!.uid,
                                        context,
                                      );
                                      setState(() {
                                        _followedSuppliers.add(supplier.id);
                                      });
                                      showSuccess(context, 'Followed ${supplier['name']}');
                                    },
                                    child: const Text("Follow"),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
        ]
      )
    );
  }
}

// ✅ Supplier Products Screen
class SupplierProductsScreen extends StatelessWidget {
  final String supplierId;
  final String supplierName;

  const SupplierProductsScreen({
    super.key,
    required this.supplierId,
    required this.supplierName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$supplierName\'s Products')),
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
            .collection('products')
            .doc(supplierId)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(child: Text('No products found', style: TextStyle(fontSize: 16, color: Colors.white)));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index];
              final data = product.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: data['imageUrl'] != null
                      ? Image.network(
                    data['imageUrl'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  )
                  : const Icon(Icons.image, size: 60),
                  title: Text(data['name'] ?? 'No name'),
                  subtitle: Text('Ksh.${data['price'] ?? '0.00'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      placeOrder(product.id, supplierId, context);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
        ]
      )
    );
  }
}

void followSupplier(String supplierId, String retailerId, BuildContext context) async {
  try {
    final docRef =
        FirebaseFirestore.instance.collection('followers').doc(supplierId);

    await docRef.set({
      'followers': FieldValue.arrayUnion([retailerId])
    }, SetOptions(merge: true));

    showSuccess(context, 'Successfully followed supplier!');
  } catch (e) {
    showError(context, 'Failed ${e.toString()}');
  }
}


// ✅ Function to place an order
Future<void> placeOrder(
  String productId,
  String supplierId,
  BuildContext context,
) async {
  try {
    final retailerId = FirebaseAuth.instance.currentUser!.uid;

    // 1) Get retailer info
    final retailerSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(retailerId)
        .get();
    final retailerData = retailerSnap.data() ?? {};
    final retailerName = retailerData['name'] ?? 'Unknown';

    // 2) Get product info (since it’s under products/{supplierId}/items/{productId})
    final productSnap = await FirebaseFirestore.instance
        .collection('products')
        .doc(supplierId)
        .collection('items')
        .doc(productId)
        .get();
    final productData = productSnap.data() ?? {};
    final productName  = productData['name'] ?? 'Unnamed product';
    final productImage = productData['imageUrl'];
    final productPrice = productData['price'];

    // (Optional) supplier name, if you store it in users
    final supplierSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(supplierId)
        .get();
    final supplierName = supplierSnap.data()?['name'];

    // 3) Write denormalized order
    await FirebaseFirestore.instance.collection('orders').add({
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,

      'supplierId': supplierId,
      'supplierName': supplierName,

      'retailerId': retailerId,
      'retailerName': retailerName,

      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    showSuccess(context, 'Order placed successfully!');
  } catch (e, st) {
    debugPrint('placeOrder failed: $e\n$st');
    showError(context, 'Failed to place order');
  }
}
