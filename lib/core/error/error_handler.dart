import 'package:flutter/material.dart';
import 'app_exception.dart';

class ErrorHandler {
  static void showError(BuildContext context, dynamic error) {
    final message = error is AppException
        ? error.message
        : 'An unexpected error occurred.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) return error.message;
    if (error is FlutterError) return error.message;
    return 'Something went wrong. Please try again.';
  }
}
