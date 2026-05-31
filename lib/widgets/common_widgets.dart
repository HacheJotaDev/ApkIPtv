import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFE50914)),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ],
      ),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFE50914), size: 48),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
