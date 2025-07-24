import 'package:flutter/material.dart';

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[800],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

String getFriendlyErrorMessage(String code) {
  switch (code) {
    case 'user-not-found':
      return 'No user found with that email.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'invalid-email':
      return 'That email address is invalid.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many login attempts. Try again later.';
    case 'network-request-failed':
      return 'No internet connection. Please check your network.';
    case 'email-already-in-use':
      return 'An account already exists with that email.';
    case 'weak-password':
      return 'The password should be at least 6 characters.';
    default:
      return 'An unexpected error occurred. Please try again.';
  }
}