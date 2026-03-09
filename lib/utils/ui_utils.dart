import 'package:flutter/material.dart';
import '../theme.dart';

class UIUtils {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    IconData? icon,
    IconData? actionIcon,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 4),
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon ??
                  (isError ? Icons.error_outline : Icons.check_circle_outline),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (actionIcon != null && onActionPressed != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onActionPressed();
                },
                icon: Icon(actionIcon, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        backgroundColor: isError
            ? Colors.redAccent.withOpacity(0.9)
            : AppTheme.primary.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        elevation: 0,
      ),
    );
  }
}

