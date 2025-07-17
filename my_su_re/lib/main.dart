import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pages/login.dart';
import 'pages/supplierDashboard.dart';
import 'pages/retailerDashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retailer/Supplier App',
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

/// Widget that checks auth state and navigates to appropriate screen
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        if (!snapshot.hasData) {
          // Not logged in
          return LoginScreen();
        }

        // Logged in
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

            final role = snapshot.data!.get('role');
            if (role == 'retailer') return RetailerApp();
            if (role == 'supplier') return SupplierDashboard(supplierId: user.uid);
            return Center(child: Text('Unknown role'));
          },
        );
      },
    );
  }
}
