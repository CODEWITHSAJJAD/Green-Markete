import '../../data/models/sale_model.dart';
import '../../data/repositories/sale_repository.dart';

class RecordSaleUseCase {
  final SaleRepository _repository;

  RecordSaleUseCase(this._repository);

  Future<SaleModel> execute(SaleCreateRequest request) {
    return _repository.create(request);
  }
}
