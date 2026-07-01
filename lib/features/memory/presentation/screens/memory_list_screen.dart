import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/memory.dart';
import '../providers/memory_provider.dart';
import 'memory_detail_screen.dart';

/// Lists every place the user has saved, with a search box and a
/// minimum-rating filter. Tapping a card opens its detail screen; the
/// map-pin button instead hands the [Memory] up to [onMemorySelected]
/// (wired by [HomeShell] to switch to the map tab and animate the camera
/// there).
class MemoryListScreen extends StatefulWidget {
  const MemoryListScreen({super.key, required this.onMemorySelected});

  final ValueChanged<Memory> onMemorySelected;

  @override
  State<MemoryListScreen> createState() => _MemoryListScreenState();
}

class _MemoryListScreenState extends State<MemoryListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  double _minRating = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Memory> _applyFilters(List<Memory> memories) {
    return memories.where((memory) {
      final matchesQuery =
          _query.isEmpty ||
          memory.title.toLowerCase().contains(_query) ||
          memory.note.toLowerCase().contains(_query);
      return matchesQuery && memory.rating >= _minRating;
    }).toList();
  }

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

    final filtered = _applyFilters(provider.memories);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Mekan adı veya notta ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              _RatingFilterChip(
                label: 'Tümü',
                selected: _minRating == 0,
                onSelected: () => setState(() => _minRating = 0),
              ),
              for (final threshold in const [3.0, 4.0, 5.0])
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _RatingFilterChip(
                    label: '${threshold.toInt()}★+',
                    selected: _minRating == threshold,
                    onSelected: () => setState(() => _minRating = threshold),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Aramanla eşleşen bir anı yok.'))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final memory = filtered[index];
                    return _MemoryCard(
                      memory: memory,
                      onOpenDetail: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              MemoryDetailScreen(memoryId: memory.id),
                        ),
                      ),
                      onShowOnMap: () => widget.onMemorySelected(memory),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RatingFilterChip extends StatelessWidget {
  const _RatingFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
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
