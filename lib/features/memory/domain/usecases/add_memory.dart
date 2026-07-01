import 'dart:io';

import '../entities/memory.dart';
import '../repositories/memory_repository.dart';

class AddMemory {
  const AddMemory(this._repository);

  final MemoryRepository _repository;

  Future<Memory> call({
    required String ownerId,
    required String title,
    required String note,
    required double latitude,
    required double longitude,
    required double rating,
    required List<File> imageFiles,
    File? videoFile,
  }) {
    return _repository.addMemory(
      ownerId: ownerId,
      title: title,
      note: note,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      imageFiles: imageFiles,
      videoFile: videoFile,
    );
  }
}
