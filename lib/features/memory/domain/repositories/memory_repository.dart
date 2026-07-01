import 'dart:io';

import '../entities/memory.dart';

abstract class MemoryRepository {
  /// Emits the given owner's memories, newest first, updating live as
  /// Firestore changes.
  Stream<List<Memory>> watchMemories(String ownerId);

  /// Uploads [imageFiles]/[videoFile] to Storage, then writes the memory
  /// document to Firestore. Returns the saved [Memory].
  Future<Memory> addMemory({
    required String ownerId,
    required String title,
    required String note,
    required double latitude,
    required double longitude,
    required double rating,
    required List<File> imageFiles,
    File? videoFile,
  });

  /// Updates an existing memory's text/rating/media.
  ///
  /// [keptPhotoUrls] are existing photo URLs that should remain;
  /// [removedPhotoUrls] are existing photo URLs to delete from Storage;
  /// [newImageFiles] are local files to upload and append.
  ///
  /// Video resolution: if [newVideoFile] is provided it becomes the new
  /// video (and [removedVideoUrl], if set, is deleted from Storage first);
  /// otherwise [keptVideoUrl] (which may be `null`) becomes the final video
  /// URL, and [removedVideoUrl] (if set) is deleted from Storage.
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
  });

  /// Deletes the memory document and every file under its Storage folder.
  Future<void> deleteMemory({
    required String ownerId,
    required String memoryId,
  });
}
