import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retailer/Supplier Signup',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SignupScreen(),
    );
  }
}

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'retailer'; // default

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Create user in Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim());

        // Save additional info to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created successfully!')),
        );

        // Navigate to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMsg = 'Signup failed';
        if (e.code == 'email-already-in-use') {
          errorMsg = 'Email already in use';
        } else if (e.code == 'invalid-email') {
          errorMsg = 'Invalid email address';
        } else if (e.code == 'weak-password') {
          errorMsg = 'Password is too weak';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Full Name"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter name" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter email";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter password";
                  }
                  if (value.length < 6) {
                    return "Password too short";
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(labelText: "Select Role"),
                items: [
                  DropdownMenuItem(
                      value: 'retailer', child: Text("Retailer")),
                  DropdownMenuItem(
                      value: 'supplier', child: Text("Supplier")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _signup,
                child: Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}