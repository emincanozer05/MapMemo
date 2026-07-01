import 'package:flutter/material.dart';

/// Placeholder for the saved-places list (Firestore-backed) that will let
/// users tap an entry to jump to its location on the map.
class MemoryListScreen extends StatelessWidget {
  const MemoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Kaydedilenler listesi bir sonraki adımda eklenecek.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
