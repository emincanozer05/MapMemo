import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapmemo/core/error/app_exceptions.dart';
import 'package:mapmemo/features/auth/domain/entities/app_user.dart';
import 'package:mapmemo/features/memory/domain/entities/memory.dart';
import 'package:mapmemo/features/memory/domain/repositories/memory_repository.dart';
import 'package:mapmemo/features/memory/domain/usecases/add_memory.dart';
import 'package:mapmemo/features/memory/domain/usecases/delete_memory.dart';
import 'package:mapmemo/features/memory/domain/usecases/update_memory.dart';
import 'package:mapmemo/features/memory/domain/usecases/watch_memories.dart';
import 'package:mapmemo/features/memory/presentation/providers/memory_provider.dart';

class FakeMemoryRepository implements MemoryRepository {
  final _controller = StreamController<List<Memory>>.broadcast();
  List<Memory> memoriesToEmit = const [];
  String? lastAddMemoryOwnerId;
  String? lastUpdateMemoryId;
  String? lastDeleteMemoryId;
  bool shouldThrow = false;

  @override
  Stream<List<Memory>> watchMemories(String ownerId) {
    scheduleMicrotask(() => _controller.add(memoriesToEmit));
    return _controller.stream;
  }

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
  }) async {
    lastAddMemoryOwnerId = ownerId;
    if (shouldThrow) {
      throw const AppException('Anı kaydedilemedi.');
    }
    return Memory(
      id: 'm1',
      ownerId: ownerId,
      title: title,
      note: note,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      photoUrls: const [],
      createdAt: DateTime.now(),
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
  }) async {
    lastUpdateMemoryId = memoryId;
    if (shouldThrow) {
      throw const AppException('Anı güncellenemedi.');
    }
    return Memory(
      id: memoryId,
      ownerId: ownerId,
      title: title,
      note: note,
      latitude: 0,
      longitude: 0,
      rating: rating,
      photoUrls: keptPhotoUrls,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteMemory({
    required String ownerId,
    required String memoryId,
  }) async {
    lastDeleteMemoryId = memoryId;
    if (shouldThrow) {
      throw const AppException('Anı silinemedi.');
    }
  }
}

void main() {
  late FakeMemoryRepository repository;
  late MemoryProvider provider;

  setUp(() {
    repository = FakeMemoryRepository();
    provider = MemoryProvider(
      watchMemories: WatchMemories(repository),
      addMemory: AddMemory(repository),
      updateMemory: UpdateMemory(repository),
      deleteMemory: DeleteMemory(repository),
    );
  });

  test('addMemory fails when no user is signed in', () async {
    final result = await provider.addMemory(
      title: 'Kahve Dükkanı',
      note: '',
      latitude: 0,
      longitude: 0,
      rating: 3,
      imageFiles: const [],
    );

    expect(result, isFalse);
    expect(provider.errorMessage, isNotNull);
  });

  test('updateUser subscribes to the owner\'s memories', () async {
    repository.memoriesToEmit = [
      Memory(
        id: 'm1',
        ownerId: 'u1',
        title: 'Sahil',
        note: '',
        latitude: 1,
        longitude: 1,
        rating: 5,
        photoUrls: const [],
        createdAt: DateTime.now(),
      ),
    ];

    provider.updateUser(const AppUser(uid: 'u1', email: 'a@b.com'));
    await Future<void>.delayed(Duration.zero);

    expect(provider.memories, hasLength(1));
    expect(provider.isLoading, isFalse);
  });

  test('updateUser(null) clears memories on sign-out', () async {
    repository.memoriesToEmit = [
      Memory(
        id: 'm1',
        ownerId: 'u1',
        title: 'Sahil',
        note: '',
        latitude: 1,
        longitude: 1,
        rating: 5,
        photoUrls: const [],
        createdAt: DateTime.now(),
      ),
    ];
    provider.updateUser(const AppUser(uid: 'u1', email: 'a@b.com'));
    await Future<void>.delayed(Duration.zero);
    expect(provider.memories, hasLength(1));

    provider.updateUser(null);

    expect(provider.memories, isEmpty);
  });

  test('addMemory tags the new memory with the signed-in owner', () async {
    provider.updateUser(const AppUser(uid: 'u1', email: 'a@b.com'));
    await Future<void>.delayed(Duration.zero);

    final result = await provider.addMemory(
      title: 'Sahil',
      note: 'Güzel manzara',
      latitude: 10,
      longitude: 20,
      rating: 4,
      imageFiles: const [],
    );

    expect(result, isTrue);
    expect(repository.lastAddMemoryOwnerId, 'u1');
    expect(provider.errorMessage, isNull);
  });

  test('addMemory surfaces repository failures as errorMessage', () async {
    repository.shouldThrow = true;
    provider.updateUser(const AppUser(uid: 'u1', email: 'a@b.com'));
    await Future<void>.delayed(Duration.zero);

    final result = await provider.addMemory(
      title: 'Sahil',
      note: '',
      latitude: 10,
      longitude: 20,
      rating: 4,
      imageFiles: const [],
    );

    expect(result, isFalse);
    expect(provider.errorMessage, 'Anı kaydedilemedi.');
  });

  test(
    'updateMemory forwards the id and clears the error on success',
    () async {
      provider.updateUser(const AppUser(uid: 'u1', email: 'a@b.com'));
      await Future<void>.delayed(Duration.zero);

      final result = await provider.updateMemory(
        memoryId: 'm1',
        title: 'Güncel ad',
        note: '',
        rating: 5,
        keptPhotoUrls: const [],
        removedPhotoUrls: const [],
        newImageFiles: const [],
      );

      expect(result, isTrue);
      expect(repository.lastUpdateMemoryId, 'm1');
      expect(provider.errorMessage, isNull);
    },
  );

  test('updateMemory surfaces repository failures as errorMessage', () async {
    repository.shouldThrow = true;
    provider.updateUser(const AppUser(uid: 'u1', email: 'a@b.com'));
    await Future<void>.delayed(Duration.zero);

    final result = await provider.updateMemory(
      memoryId: 'm1',
      title: 'Güncel ad',
      note: '',
      rating: 5,
      keptPhotoUrls: const [],
      removedPhotoUrls: const [],
      newImageFiles: const [],
    );

    expect(result, isFalse);
    expect(provider.errorMessage, 'Anı güncellenemedi.');
  });

  test('deleteMemory fails when no user is signed in', () async {
    final result = await provider.deleteMemory('m1');

    expect(result, isFalse);
    expect(provider.errorMessage, isNotNull);
  });

  test('deleteMemory forwards the id on success', () async {
    provider.updateUser(const AppUser(uid: 'u1', email: 'a@b.com'));
    await Future<void>.delayed(Duration.zero);

    final result = await provider.deleteMemory('m1');

    expect(result, isTrue);
    expect(repository.lastDeleteMemoryId, 'm1');
    expect(provider.errorMessage, isNull);
  });
}
