import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<List<String>> getFollowers(String supplierId) async {
    final doc = await _db.collection('followers').doc(supplierId).get();
    if (doc.exists && doc.data() != null && doc.data()!['followers'] != null) {
      return List<String>.from(doc['followers']);
    }
    return [];
  }

  Stream<QuerySnapshot> getProductsStream(String supplierId) {
    return _db
        .collection('products')
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> submitProduct({
    String? productId,
    required Map<String, dynamic> data,
  }) {
    if (productId == null) {
      // Add new product
      return _db.collection('products').add(data);
    } else {
      // Update existing product
      return _db.collection('products').doc(productId).update(data);
    }
  }

  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }
}