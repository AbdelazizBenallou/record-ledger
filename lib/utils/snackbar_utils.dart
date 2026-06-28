import 'package:flutter/material.dart';

void showSuccessSnackBar(BuildContext context, String message) {
  _showColoredSnackBar(context, message, Colors.green);
}

void showErrorSnackBar(BuildContext context, String message) {
  _showColoredSnackBar(context, message, Colors.red);
}

void _showColoredSnackBar(BuildContext context, String message, Color bgColor) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            bgColor == Colors.green ? Icons.check_circle : Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}
