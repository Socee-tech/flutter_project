import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'RetailerDashboard.dart';
import 'supplierDashboard.dart';
import 'signup.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim());

        String uid = userCredential.user!.uid;

        // Fetch user role from Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          String role = userDoc['role'];
          if (role == 'retailer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => RetailerApp()),
            );
          } else if (role == 'supplier') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => SupplierDashboard(supplierId: uid)),
            );
          } else {
            _showError("Unknown user role.");
          }
        } else {
          _showError("User record not found in Firestore.");
        }
      } on FirebaseAuthException catch (e) {
        _showError(e.message ?? "Login failed");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter email" : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? "Password too short" : null,
              ),
              SizedBox(height: 20),
              TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupScreen()),
                );
              },
              child: Text("Don't have an account? Sign up here"),
            ),
              ElevatedButton(
                onPressed: _login,
                child: Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}