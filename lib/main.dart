import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_su_re/locator.dart';
import 'package:my_su_re/pages/signup.dart';
import 'package:my_su_re/services/auth_service.dart';
import 'package:my_su_re/services/navigation_service.dart';
import 'package:my_su_re/services/role_service.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_su_re/pages/login.dart';
import 'package:my_su_re/pages/supplier_dashboard.dart';
import 'package:my_su_re/pages/retailer_dashboard.dart';
import 'package:my_su_re/splash_screen.dart';
import 'package:my_su_re/pages/home.dart';
import 'package:my_su_re/pages/forgot_password.dart';
import 'package:my_su_re/theme.dart';
import 'package:my_su_re/pages/follower_list_screen.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // Main entry point of the app
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'Retailer/Supplier App',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        navigatorKey: locator<NavigationService>().navigatorKey,
        home: Consumer<AuthService>(
          builder: (context, authService, child) {
            return StreamBuilder<User?>(
              stream: authService.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const WelcomeSplashScreen();
                }

                return FutureBuilder<String?>(
                  future: locator<RoleService>().getRole(),
                  builder: (context, roleSnapshot) {
                    if (roleSnapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (roleSnapshot.hasError || !roleSnapshot.hasData) {
                      // Handle error or user not found in Firestore
                      return const LoginScreen();
                    }

                    final role = roleSnapshot.data;
                    if (role == 'retailer') {
                      return const RetailerDashboard();
                    } else if (role == 'supplier') {
                      return SupplierDashboard(
                          supplierId: authService.currentUser!.uid);
                    }

                    // Handle unknown role
                    return const LoginScreen();
                  },
                );
              },
            );
          },
        ),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/supplierDashboard': (context) => SupplierDashboard(
              supplierId: context.read<AuthService>().currentUser?.uid ?? ''),
          '/retailerDashboard': (context) => const RetailerDashboard(),
          '/home': (context) => const HomeScreen(),
          '/forgotPassword': (context) => const ForgotPasswordScreen(),
          '/followerList': (context) => FollowerListScreen(
              supplierId: context.read<AuthService>().currentUser?.uid ?? ''),
        },
      ),
    );
  }
}
