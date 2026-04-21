import 'dart:async';

import '../../../../shared/models/models.dart';
import '../../../../shared/services/api_service.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService _api;
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  AuthRepositoryImpl(this._api);

  @override
  Future<UserModel> login(
      {required String email, required String password}) async {
    final response = await _api.post(
      '/auth/login',
      authorized: false,
      data: {'email': email, 'password': password},
    );
    final token = (response['access_token'] ?? '').toString();
    final rawUser = response['user'];
    if (token.isEmpty || rawUser is! Map<String, dynamic>) {
      throw Exception('Invalid login response from server');
    }

    await _api.saveToken(token);
    final userMap = _toUserMap(rawUser);
    await _api.saveCurrentUser(userMap);

    _currentUser = UserModel.fromMap(userMap);
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> register(
      {required UserModel user,
      required String password,
      List<String> selectedCourseIds = const []}) async {
    final response = await _api.post(
      '/auth/register',
      authorized: false,
      data: {
        'full_name': user.fullName,
        'email': user.email,
        'password': password,
        'matric_number': user.matricNumber,
        'department': user.department,
        'phone_number': user.phoneNumber,
        'role': user.role,
        'selected_course_ids': selectedCourseIds,
      },
    );

    final token = (response['access_token'] ?? '').toString();
    final rawUser = response['user'];
    if (token.isEmpty || rawUser is! Map<String, dynamic>) {
      throw Exception('Invalid registration response from server');
    }

    await _api.saveToken(token);
    final userMap = _toUserMap(rawUser);
    await _api.saveCurrentUser(userMap);

    _currentUser = UserModel.fromMap(userMap);
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await _api.clearAuth();
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final token = await _api.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final me = await _api.get('/auth/me');
      final raw = me['user'];
      if (raw is Map<String, dynamic>) {
        final userMap = _toUserMap(raw);
        await _api.saveCurrentUser(userMap);
        _currentUser = UserModel.fromMap(userMap);
        return _currentUser;
      }
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('blocked')) {
        await logout();
        return null;
      }
      // Fall back to cached profile if backend refresh fails.
    }

    final cachedUser = await _api.getCurrentUser();
    if (cachedUser == null) return null;
    _currentUser = UserModel.fromMap(cachedUser);
    if (!_currentUser!.isActive) {
      await logout();
      return null;
    }
    return _currentUser;
  }

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  Map<String, dynamic> _toUserMap(Map<String, dynamic> raw) {
    return {
      'id': raw['id'] ?? '',
      'fullName': raw['full_name'] ?? raw['fullName'] ?? '',
      'email': raw['email'] ?? '',
      'matricNumber': raw['matric_number'] ?? raw['matricNumber'] ?? '',
      'department': raw['department'] ?? '',
      'phoneNumber': raw['phone_number'] ?? raw['phoneNumber'] ?? '',
      'role': raw['role'] ?? 'student',
      'deviceId': raw['device_id'] ?? raw['deviceId'],
      'createdAt': raw['created_at'] ??
          raw['createdAt'] ??
          DateTime.now().toIso8601String(),
      'isActive': raw['is_active'] ?? raw['isActive'] ?? true,
      'blockedAt': raw['blocked_at'] ?? raw['blockedAt'],
      'blockedReason': raw['blocked_reason'] ?? raw['blockedReason'],
    };
  }
}
