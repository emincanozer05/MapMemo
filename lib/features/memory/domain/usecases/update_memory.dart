import 'dart:io';

import '../entities/memory.dart';
import '../repositories/memory_repository.dart';

class UpdateMemory {
  const UpdateMemory(this._repository);

  final MemoryRepository _repository;

  Future<Memory> call({
    required String memoryId,
    required String ownerId,
    required String title,
    required String note,
    required double rating,
    required List<String> keptPhotoUrls,
    required List<String> removedPhotoUrls,
    required List<File> newImageFiles,
    String? keptVideoUrl,
    String? removedVideoUrl,
    File? newVideoFile,
  }) {
    return _repository.updateMemory(
      memoryId: memoryId,
      ownerId: ownerId,
      title: title,
      note: note,
      rating: rating,
      keptPhotoUrls: keptPhotoUrls,
      removedPhotoUrls: removedPhotoUrls,
      newImageFiles: newImageFiles,
      keptVideoUrl: keptVideoUrl,
      removedVideoUrl: removedVideoUrl,
      newVideoFile: newVideoFile,
    );
  }
}
