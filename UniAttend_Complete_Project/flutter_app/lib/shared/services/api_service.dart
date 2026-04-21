import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class ApiService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user_json';

  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  Future<Map<String, dynamic>> get(
    String path, {
    bool authorized = true,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final options = await _buildOptions(authorized: authorized);
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    bool authorized = true,
    Map<String, dynamic>? data,
  }) async {
    try {
      final options = await _buildOptions(authorized: authorized);
      final response = await _dio.post(path, data: data, options: options);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    bool authorized = true,
    Map<String, dynamic>? data,
  }) async {
    try {
      final options = await _buildOptions(authorized: authorized);
      final response = await _dio.put(path, data: data, options: options);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool authorized = true,
    Map<String, dynamic>? data,
  }) async {
    try {
      final options = await _buildOptions(authorized: authorized);
      final response = await _dio.delete(path, data: data, options: options);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveCurrentUser(Map<String, dynamic> userMap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userMap));
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<Options> _buildOptions({required bool authorized}) async {
    final headers = <String, dynamic>{};
    if (authorized) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return Options(headers: headers);
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid server response');
  }

  static String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
    return 'Network request failed';
  }
}
