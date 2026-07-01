import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/memory.dart';
import '../providers/memory_provider.dart';

/// BottomSheet form pre-filled from an existing [Memory]. Lets the user
/// change the name/note/rating, remove existing photos or the video, and
/// add new photos/video, then saves through [MemoryProvider.updateMemory].
class EditMemorySheet extends StatefulWidget {
  const EditMemorySheet({super.key, required this.memory});

  final Memory memory;

  static Future<bool?> show(BuildContext context, Memory memory) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditMemorySheet(memory: memory),
    );
  }

  @override
  State<EditMemorySheet> createState() => _EditMemorySheetState();
}

class _EditMemorySheetState extends State<EditMemorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  final _picker = ImagePicker();

  late double _rating;
  late List<String> _keptPhotoUrls;
  final List<XFile> _newImages = [];
  String? _keptVideoUrl;
  XFile? _newVideo;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memory.title);
    _noteController = TextEditingController(text: widget.memory.note);
    _rating = widget.memory.rating;
    _keptPhotoUrls = [...widget.memory.photoUrls];
    _keptVideoUrl = widget.memory.videoUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty || !mounted) return;
    setState(() => _newImages.addAll(picked));
  }

  Future<void> _captureImageWithCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null || !mounted) return;
    setState(() => _newImages.add(photo));
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 2),
    );
    if (video == null || !mounted) return;
    setState(() {
      _newVideo = video;
      _keptVideoUrl = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final original = widget.memory;
    final removedPhotoUrls = original.photoUrls
        .where((url) => !_keptPhotoUrls.contains(url))
        .toList();

    String? removedVideoUrl;
    if (original.videoUrl != null &&
        (_newVideo != null || _keptVideoUrl == null)) {
      removedVideoUrl = original.videoUrl;
    }

    final provider = context.read<MemoryProvider>();
    final success = await provider.updateMemory(
      memoryId: original.id,
      title: _titleController.text.trim(),
      note: _noteController.text.trim(),
      rating: _rating,
      keptPhotoUrls: _keptPhotoUrls,
      removedPhotoUrls: removedPhotoUrls,
      newImageFiles: _newImages.map((x) => File(x.path)).toList(),
      keptVideoUrl: _keptVideoUrl,
      removedVideoUrl: removedVideoUrl,
      newVideoFile: _newVideo == null ? null : File(_newVideo!.path),
    );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      final message = provider.errorMessage ?? 'Anı güncellenemedi.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<MemoryProvider>().isSaving;
    final hasMedia =
        _keptPhotoUrls.isNotEmpty ||
        _newImages.isNotEmpty ||
        _keptVideoUrl != null ||
        _newVideo != null;

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
                'Anıyı Düzenle',
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
              if (hasMedia) ...[
                _EditMediaPreview(
                  keptPhotoUrls: _keptPhotoUrls,
                  newImages: _newImages,
                  keptVideoUrl: _keptVideoUrl,
                  newVideo: _newVideo,
                  onRemoveExistingPhoto: (url) =>
                      setState(() => _keptPhotoUrls.remove(url)),
                  onRemoveNewImage: (index) =>
                      setState(() => _newImages.removeAt(index)),
                  onRemoveVideo: () => setState(() {
                    _keptVideoUrl = null;
                    _newVideo = null;
                  }),
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
                    label: const Text('Video Ekle/Değiştir'),
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

class _EditMediaPreview extends StatelessWidget {
  const _EditMediaPreview({
    required this.keptPhotoUrls,
    required this.newImages,
    required this.keptVideoUrl,
    required this.newVideo,
    required this.onRemoveExistingPhoto,
    required this.onRemoveNewImage,
    required this.onRemoveVideo,
  });

  final List<String> keptPhotoUrls;
  final List<XFile> newImages;
  final String? keptVideoUrl;
  final XFile? newVideo;
  final ValueChanged<String> onRemoveExistingPhoto;
  final ValueChanged<int> onRemoveNewImage;
  final VoidCallback onRemoveVideo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final url in keptPhotoUrls)
            _Thumbnail(
              onRemove: () => onRemoveExistingPhoto(url),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (_, _) =>
                    const ColoredBox(color: Color(0xFFEDEFF2)),
              ),
            ),
          for (var i = 0; i < newImages.length; i++)
            _Thumbnail(
              onRemove: () => onRemoveNewImage(i),
              child: Image.file(
                File(newImages[i].path),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
          if (keptVideoUrl != null || newVideo != null)
            _Thumbnail(
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.child, required this.onRemove});

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
