import 'package:flutter/material.dart';

/// Placeholder for the interactive `google_maps_flutter` map.
///
/// Long-press-to-add-marker + the "add memory" bottom sheet form are built
/// in the next step; this screen only establishes where that code will
/// live so the bottom navigation shell has something to show today.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'İnteraktif harita bir sonraki adımda eklenecek.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
