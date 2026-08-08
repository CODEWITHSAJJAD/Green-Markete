import 'package:flutter/material.dart';

import '../../core/config/theme.dart';

void _showSnack(BuildContext context, {required Widget content, required Color bg}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
}

void showErrorSnackbar(BuildContext context, String message) {
  _showSnack(
    context,
    bg: AppColors.error,
    content: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
      ],
    ),
  );
}

void showSuccessSnackbar(BuildContext context, String message) {
  _showSnack(
    context,
    bg: AppColors.success,
    content: Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
      ],
    ),
  );
}
