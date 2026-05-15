import 'package:flutter/material.dart';

class PermissionRequestWidget extends StatelessWidget {
  const PermissionRequestWidget({
    super.key,
    required this.onRequestPermission,
    this.message,
    this.onOpenSettings,
  });

  final String? message;
  final VoidCallback onRequestPermission;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                message ?? 'Requesting camera access…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRequestPermission,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
              if (onOpenSettings != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Open settings'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}