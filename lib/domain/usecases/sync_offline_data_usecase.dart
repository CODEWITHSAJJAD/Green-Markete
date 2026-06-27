import '../../data/repositories/sync_repository.dart';

class SyncOfflineDataUseCase {
  final SyncRepository _repository;

  SyncOfflineDataUseCase(this._repository);

  Future<void> execute() {
    return _repository.processQueue();
  }
}
