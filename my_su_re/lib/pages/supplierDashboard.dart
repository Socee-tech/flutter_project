import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SupplierDashboard extends StatefulWidget {
  final String supplierId;

  SupplierDashboard({required this.supplierId});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descController = TextEditingController();
  TextEditingController _priceController = TextEditingController();

  File? _imageFile;
  List<String> _followers = [];

  // Used for editing
  String? _editingProductId;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    final doc = await FirebaseFirestore.instance
        .collection('followers')
        .doc(widget.supplierId)
        .get();

    if (doc.exists) {
      List<dynamic> raw = doc['followers'] ?? [];
      setState(() => _followers = List<String>.from(raw));
    }
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate()) return;

    String imageUrl = '';
    if (_imageFile != null) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref =
          FirebaseStorage.instance.ref('product_images/$fileName');
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    final data = {
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'price': double.tryParse(_priceController.text.trim()) ?? 0,
      'supplierId': widget.supplierId,
      'createdAt': Timestamp.now(),
    };

    if (_editingProductId == null) {
      // Add new
      data['imageUrl'] = imageUrl;
      await FirebaseFirestore.instance.collection('products').add(data);
    } else {
      // Update existing
      if (imageUrl.isNotEmpty) data['imageUrl'] = imageUrl;
      await FirebaseFirestore.instance
          .collection('products')
          .doc(_editingProductId)
          .update(data);
    }

    _resetForm();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Product ${_editingProductId == null ? 'added' : 'updated'}")),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _descController.clear();
    _priceController.clear();
    setState(() {
      _imageFile = null;
      _editingProductId = null;
    });
  }

  Future<void> _editProduct(DocumentSnapshot doc) async {
    setState(() {
      _nameController.text = doc['name'];
      _descController.text = doc['description'];
      _priceController.text = doc['price'].toString();
      _editingProductId = doc.id;
    });
  }

  Future<void> _deleteProduct(String id) async {
    await FirebaseFirestore.instance.collection('products').doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Product deleted')),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.supplierId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Supplier Dashboard"),
        actions: [
          IconButton(onPressed: _logout, icon: Icon(Icons.logout)),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: _loadProfile(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final profile = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hello, ${profile['name']} 👋",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Email: ${profile['email']}"),
                  Text("Role: ${profile['role']}"),
                ],
              );
            },
          ),
          Divider(height: 30),
          Text("Add/Edit Product", style: TextStyle(fontSize: 18)),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name'),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              if (_imageFile != null)
                Image.file(_imageFile!, height: 100, fit: BoxFit.cover),
              TextButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.image),
                label: Text("Pick Image"),
              ),
              ElevatedButton(
                onPressed: _submitProduct,
                child: Text(_editingProductId == null
                    ? "Add Product"
                    : "Update Product"),
              ),
              if (_editingProductId != null)
                TextButton(
                  onPressed: _resetForm,
                  child: Text("Cancel Editing"),
                )
            ]),
          ),
          Divider(height: 30),
          Text("Your Products", style: TextStyle(fontSize: 18)),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('supplierId', isEqualTo: widget.supplierId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              final docs = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (_, index) {
                  final doc = docs[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: doc['imageUrl'] != null
                          ? Image.network(doc['imageUrl'], width: 50)
                          : Icon(Icons.image_not_supported),
                      title: Text(doc['name']),
                      subtitle: Text("Ksh ${doc['price']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _editProduct(doc)),
                          IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteProduct(doc.id)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Divider(height: 30),
          Text("Followers (${_followers.length})", style: TextStyle(fontSize: 18)),
          ..._followers.map((uid) => ListTile(
                leading: Icon(Icons.person),
                title: Text("Retailer UID: $uid"),
              )),
        ]),
      ),
    );
  }
}
