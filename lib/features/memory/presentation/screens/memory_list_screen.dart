import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/memory.dart';
import '../providers/memory_provider.dart';
import 'memory_detail_screen.dart';

/// Lists every place the user has saved. Tapping a card opens its detail
/// screen; the map-pin button instead hands the [Memory] up to
/// [onMemorySelected] (wired by [HomeShell] to switch to the map tab and
/// animate the camera there).
class MemoryListScreen extends StatelessWidget {
  const MemoryListScreen({super.key, required this.onMemorySelected});

  final ValueChanged<Memory> onMemorySelected;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MemoryProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.memories.isEmpty) {
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
                'Henüz kaydedilmiş bir anın yok.\n'
                'Haritada bir yere uzun basarak başla!',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.memories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final memory = provider.memories[index];
        return _MemoryCard(
          memory: memory,
          onOpenDetail: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MemoryDetailScreen(memoryId: memory.id),
            ),
          ),
          onShowOnMap: () => onMemorySelected(memory),
        );
      },
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({
    required this.memory,
    required this.onOpenDetail,
    required this.onShowOnMap,
  });

  final Memory memory;
  final VoidCallback onOpenDetail;
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _Thumbnail(
                url: memory.photoUrls.isEmpty ? null : memory.photoUrls.first,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (memory.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        memory.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          Icon(
                            i < memory.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 16,
                            color: const Color(0xFFFBBC05),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Haritada göster',
                icon: const Icon(Icons.map_outlined),
                onPressed: onShowOnMap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 64,
        height: 64,
        child: url == null
            ? const ColoredBox(
                color: Color(0xFFEDEFF2),
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.black38,
                ),
              )
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ColoredBox(color: Color(0xFFEDEFF2)),
                errorWidget: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }
}
