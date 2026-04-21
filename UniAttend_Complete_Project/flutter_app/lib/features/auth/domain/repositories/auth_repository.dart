// lib/features/auth/domain/repositories/auth_repository.dart
import '../../../../shared/models/models.dart';

abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required UserModel user,
    required String password,
    List<String> selectedCourseIds,
  });
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}
