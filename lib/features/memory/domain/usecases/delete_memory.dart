import '../repositories/memory_repository.dart';

class DeleteMemory {
  const DeleteMemory(this._repository);

  final MemoryRepository _repository;

  Future<void> call({required String ownerId, required String memoryId}) {
    return _repository.deleteMemory(ownerId: ownerId, memoryId: memoryId);
  }
}
