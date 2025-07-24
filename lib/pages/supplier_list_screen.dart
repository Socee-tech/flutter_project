import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_su_re/utils/helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({Key? key}) : super(key: key);

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
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
        title: const Text("Suppliers"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'supplier')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No suppliers found."));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var supplier = snapshot.data!.docs[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(supplier['name'][0]),
                ),
                title: Text(supplier['name']),
                subtitle: Text(supplier['email']),
                trailing: _followedSuppliers.contains(supplier.id)
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
                          );
                          setState(() {
                            _followedSuppliers.add(supplier.id);
                          });
                          showSuccess(context, 'Followed ${supplier['name']}');
                        },
                        child: const Text("Follow"),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}

void followSupplier(String supplierId, String retailerId) async {
  final docRef =
      FirebaseFirestore.instance.collection('followers').doc(supplierId);

  await docRef.set({
    'followers': FieldValue.arrayUnion([retailerId])
  }, SetOptions(merge: true));
}