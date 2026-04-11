import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import '../models/user_model.dart';

const _storage = FlutterSecureStorage();

// ── Auth state ────────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<UserModel?> {
  final _dio = ApiClient().dio;

  @override
  Future<UserModel?> build() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;
    try {
      final res = await _dio.get('/users/me');
      return UserModel.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _storage.write(key: 'access_token',  value: res.data['access_token']);
      await _storage.write(key: 'refresh_token', value: res.data['refresh_token']);
      await _storage.write(key: 'user_role',     value: res.data['role']);

      final meRes = await _dio.get('/users/me');
      state = AsyncData(UserModel.fromJson(meRes.data));
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Erreur de connexion';
      state = AsyncError(msg, StackTrace.current);
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = const AsyncLoading();
    try {
      await _dio.post('/auth/register', data: data);
      await login(data['email'] as String, data['password'] as String);
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? 'Erreur d\'inscription';
      state = AsyncError(msg, StackTrace.current);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AsyncData(null);
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword(String token, String newPassword) async {
    await _dio.post('/auth/reset-password', data: {
      'token': token,
      'new_password': newPassword,
    });
  }

  Future<void> refreshCurrentUser() async {
    try {
      final res = await _dio.get('/users/me');
      state = AsyncData(UserModel.fromJson(res.data));
    } catch (_) {}
  }
}

final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

// Helper providers
final currentUserProvider = Provider<UserModel?>((ref) =>
    ref.watch(authStateProvider).value);

final userRoleProvider = Provider<String>((ref) =>
    ref.watch(currentUserProvider)?.role ?? '');
