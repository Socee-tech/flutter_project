import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Make sure firebase_core is initialized
  runApp(RetailerApp());
}

class RetailerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retailer App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      // Set the home screen to SuppliersListScreen
      home: SuppliersListScreen(),
    );
  }
}

// ✅ Stateful Supplier List Screen
class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  _SuppliersListScreenState createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suppliers'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
              // Optionally, navigate to your login screen here
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'supplier')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final suppliers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: suppliers.length,
            itemBuilder: (context, index) {
              var supplier = suppliers[index];
              return ListTile(
                title: Text(supplier['name']),
                trailing: IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () {
                    followSupplier(
                        supplier.id,
                      FirebaseAuth.instance.currentUser!.uid,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Followed ${supplier['name']}')),
                    );
                  },
                ),
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
              );
            },
          );
        },
      ),
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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('supplierId', isEqualTo: supplierId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return Center(child: Text('No products found'));
          }

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              var product = products[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  leading: Image.network(
                    product['imageUrl'],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.broken_image),
                  ),
                  title: Text(product['name']),
                  subtitle: Text('\$${product['price']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.shopping_cart),
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
    );
  }
}

// ✅ Function to follow a supplier
void followSupplier(String supplierId, String retailerId) async {
  final docRef =
      FirebaseFirestore.instance.collection('followers').doc(supplierId);

  await docRef.set({
    'followers': FieldValue.arrayUnion([retailerId])
  }, SetOptions(merge: true));
}

// ✅ Function to place an order
void placeOrder(String productId, String supplierId, BuildContext context) async {
  final retailerId = FirebaseAuth.instance.currentUser!.uid;

  await FirebaseFirestore.instance.collection('orders').add({
    'productId': productId,
    'supplierId': supplierId,
    'retailerId': retailerId,
    'status': 'pending',
    'timestamp': FieldValue.serverTimestamp(),
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Order placed successfully!')),
  );
}
