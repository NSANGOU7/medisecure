import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AdminService {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/admin/stats');
    return Map<String, dynamic>.from(res.data);
  }

  Future<List<UserModel>> getAllUsers() async {
    final res = await _dio.get('/admin/users');
    return (res.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/admin/users/$id', data: data);
    return UserModel.fromJson(res.data);
  }

  Future<void> deleteUser(int id) async {
    await _dio.delete('/admin/users/$id');
  }

  Future<List<Map<String, dynamic>>> getLogs({int limit = 100}) async {
    final res = await _dio.get('/admin/logs', queryParameters: {'limit': limit});
    return List<Map<String, dynamic>>.from(res.data);
  }
}

final adminServiceProvider = Provider((_) => AdminService());
final adminStatsProvider = FutureProvider.autoDispose((ref) => ref.watch(adminServiceProvider).getStats());
final allUsersProvider = FutureProvider.autoDispose((ref) => ref.watch(adminServiceProvider).getAllUsers());
final logsProvider = FutureProvider.autoDispose((ref) => ref.watch(adminServiceProvider).getLogs());
