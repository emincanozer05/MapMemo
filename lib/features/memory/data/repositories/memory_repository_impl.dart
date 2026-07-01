import 'dart:io';

import '../../domain/entities/memory.dart';
import '../../domain/repositories/memory_repository.dart';
import '../datasources/memory_remote_data_source.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  const MemoryRepositoryImpl(this._remoteDataSource);

  final MemoryRemoteDataSource _remoteDataSource;

  @override
  Stream<List<Memory>> watchMemories(String ownerId) =>
      _remoteDataSource.watchMemories(ownerId);

  @override
  Future<Memory> addMemory({
    required String ownerId,
    required String title,
    required String note,
    required double latitude,
    required double longitude,
    required double rating,
    required List<File> imageFiles,
    File? videoFile,
  }) {
    return _remoteDataSource.addMemory(
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

  @override
  Future<Memory> updateMemory({
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
    return _remoteDataSource.updateMemory(
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

  @override
  Future<void> deleteMemory({
    required String ownerId,
    required String memoryId,
  }) {
    return _remoteDataSource.deleteMemory(ownerId: ownerId, memoryId: memoryId);
  }
}
