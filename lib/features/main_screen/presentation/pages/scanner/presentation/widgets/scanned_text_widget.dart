import 'package:flutter/material.dart';

class ScannedTextDialog extends StatelessWidget {
  const ScannedTextDialog({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scanned content'),
      content: SelectionArea(
        child: SingleChildScrollView(
          child: Text(text),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}