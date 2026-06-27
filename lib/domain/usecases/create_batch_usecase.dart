import '../../data/models/batch_model.dart';
import '../../data/repositories/batch_repository.dart';

class CreateBatchUseCase {
  final BatchRepository _repository;

  CreateBatchUseCase(this._repository);

  Future<BatchModel> execute(BatchCreateRequest request) {
    return _repository.create(request);
  }
}
