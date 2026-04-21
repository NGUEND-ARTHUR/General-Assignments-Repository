import '../../../../shared/models/models.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repo;
  LoginUseCase(this._repo);

  Future<UserModel> call({required String email, required String password}) =>
      _repo.login(email: email, password: password);
}

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase(this._repo);

  Future<UserModel> call({
    required UserModel user,
    required String password,
    List<String> selectedCourseIds = const [],
  }) =>
      _repo.register(
        user: user,
        password: password,
        selectedCourseIds: selectedCourseIds,
      );
}

class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase(this._repo);
  Future<void> call() => _repo.logout();
}
