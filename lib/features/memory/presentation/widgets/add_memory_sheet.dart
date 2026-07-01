import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/memory_provider.dart';

/// BottomSheet form opened when the user taps the pending marker they just
/// long-pressed onto the map. Collects the memory's name, note, rating and
/// media, then saves it through [MemoryProvider].
class AddMemorySheet extends StatefulWidget {
  const AddMemorySheet({super.key, required this.position});

  final LatLng position;

  /// Shows the sheet and returns `true` if a memory was saved.
  static Future<bool?> show(BuildContext context, LatLng position) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddMemorySheet(position: position),
    );
  }

  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<AddMemorySheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _picker = ImagePicker();

  double _rating = 4;
  final List<XFile> _images = [];
  XFile? _video;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty || !mounted) return;
    setState(() => _images.addAll(picked));
  }

  Future<void> _captureImageWithCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null || !mounted) return;
    setState(() => _images.add(photo));
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (video == null || !mounted) return;
    setState(() => _video = video);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MemoryProvider>();
    final success = await provider.addMemory(
      title: _titleController.text.trim(),
      note: _noteController.text.trim(),
      latitude: widget.position.latitude,
      longitude: widget.position.longitude,
      rating: _rating,
      imageFiles: _images.map((x) => File(x.path)).toList(),
      videoFile: _video == null ? null : File(_video!.path),
    );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final message = provider.errorMessage ?? 'Anı kaydedilemedi.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<MemoryProvider>().isSaving;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Yeni Anı Ekle',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Mekan adı'),
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Mekan adı gerekli'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Not / açıklama'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Text('Puan', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                itemCount: 5,
                itemSize: 32,
                itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                itemBuilder: (context, _) =>
                    const Icon(Icons.star_rounded, color: Color(0xFFFBBC05)),
                onRatingUpdate: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 16),
              Text(
                'Fotoğraf / Video',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (_images.isNotEmpty || _video != null) ...[
                _MediaPreviewRow(
                  images: _images,
                  video: _video,
                  onRemoveImage: (index) =>
                      setState(() => _images.removeAt(index)),
                  onRemoveVideo: () => setState(() => _video = null),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImagesFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeriden Ekle'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _captureImageWithCamera,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kameradan Çek'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video Ekle'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isSaving ? null : _save,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPreviewRow extends StatelessWidget {
  const _MediaPreviewRow({
    required this.images,
    required this.video,
    required this.onRemoveImage,
    required this.onRemoveVideo,
  });

  final List<XFile> images;
  final XFile? video;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onRemoveVideo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < images.length; i++)
            _MediaThumbnail(
              onRemove: () => onRemoveImage(i),
              child: Image.file(
                File(images[i].path),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
          if (video != null)
            _MediaThumbnail(
              onRemove: onRemoveVideo,
              child: Container(
                width: 72,
                height: 72,
                color: Colors.black87,
                child: const Icon(Icons.videocam, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
