import 'package:flutter/material.dart';

import '../../widgets/app_ui.dart';

class ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorStateWidget({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    String message = 'Something went wrong.';
    String hint = '';
    IconData icon = Icons.error_outline;

    if (error.contains('500') || error.contains('Internal Server Error')) {
      message = 'The server encountered an error.';
      hint =
          'This may be due to missing data or the biometric device being offline. Data will appear once the device syncs.';
      icon = Icons.dns_outlined;
    } else if (error.contains('connection') ||
        error.contains('XMLHttpRequest') ||
        error.contains('SocketException')) {
      message = 'Cannot connect to the server.';
      hint = 'Make sure the Spring Boot backend is running on port 8080.';
      icon = Icons.wifi_off_outlined;
    } else if (error.contains('403') || error.contains('Forbidden')) {
      message = 'Access denied.';
      hint = 'Your session may have expired. Try signing out and back in.';
      icon = Icons.lock_outline;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: AppEmptyState(
          icon: icon,
          title: message,
          description: hint.isEmpty ? error : hint,
          actionLabel: onRetry != null ? 'Retry' : null,
          onAction: onRetry,
        ),
      ),
    );
  }
}
