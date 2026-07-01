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
}
