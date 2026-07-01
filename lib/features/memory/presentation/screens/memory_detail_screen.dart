import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/memory.dart';
import '../providers/memory_provider.dart';
import '../widgets/edit_memory_sheet.dart';

/// Full details for one saved place: photo carousel, video playback, note,
/// rating, and edit/delete actions.
///
/// Takes a [memoryId] rather than a [Memory] snapshot so it always reflects
/// the live Firestore data (including right after an edit).
class MemoryDetailScreen extends StatefulWidget {
  const MemoryDetailScreen({super.key, required this.memoryId});

  final String memoryId;

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  static final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  VideoPlayerController? _videoController;
  String? _initializedVideoUrl;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _ensureVideoController(String url) async {
    if (_initializedVideoUrl == url) return;
    _initializedVideoUrl = url;
    final old = _videoController;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;
    old?.dispose();
    await controller.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _confirmDelete(Memory memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Anıyı sil'),
        content: const Text(
          'Bu anıyı silmek istediğine emin misin? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Sil',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<MemoryProvider>();
    final success = await provider.deleteMemory(memory.id);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Anı silinemedi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memories = context.watch<MemoryProvider>().memories;
    Memory? memory;
    for (final candidate in memories) {
      if (candidate.id == widget.memoryId) {
        memory = candidate;
        break;
      }
    }

    if (memory == null) {
      return const Scaffold(
        body: Center(child: Text('Bu anı artık mevcut değil.')),
      );
    }

    if (memory.videoUrl != null) {
      _ensureVideoController(memory.videoUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(memory.title),
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => EditMemorySheet.show(context, memory!),
          ),
          IconButton(
            tooltip: 'Sil',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(memory!),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (memory.photoUrls.isNotEmpty) ...[
            _PhotoCarousel(urls: memory.photoUrls),
            const SizedBox(height: 16),
          ],
          if (memory.videoUrl != null) ...[
            _VideoPlayerSection(controller: _videoController),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Icon(
                  i < memory.rating.round()
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: const Color(0xFFFBBC05),
                ),
              const SizedBox(width: 8),
              Text(memory.rating.toStringAsFixed(1)),
            ],
          ),
          if (memory.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(memory.note, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          Text(
            _dateFormat.format(memory.createdAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.urls});

  final List<String> urls;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.urls.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => CachedNetworkImage(
                imageUrl: widget.urls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, _) =>
                    const ColoredBox(color: Color(0xFFEDEFF2)),
                errorWidget: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.urls.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black26,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VideoPlayerSection extends StatelessWidget {
  const _VideoPlayerSection({required this.controller});

  final VideoPlayerController? controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null || !c.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Color(0xFFEDEFF2),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: c.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(c),
            _PlayPauseOverlay(controller: c),
          ],
        ),
      ),
    );
  }
}

class _PlayPauseOverlay extends StatefulWidget {
  const _PlayPauseOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_PlayPauseOverlay> createState() => _PlayPauseOverlayState();
}

class _PlayPauseOverlayState extends State<_PlayPauseOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onValueChanged);
    super.dispose();
  }

  void _onValueChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    return GestureDetector(
      onTap: () {
        isPlaying ? widget.controller.pause() : widget.controller.play();
      },
      child: AnimatedOpacity(
        opacity: isPlaying ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          color: Colors.black26,
          child: const Center(
            child: Icon(Icons.play_arrow, color: Colors.white, size: 56),
          ),
        ),
      ),
    );
  }
}
