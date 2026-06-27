import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<UserModel> execute(String email, String password) {
    return _repository.login(email, password);
  }
}
