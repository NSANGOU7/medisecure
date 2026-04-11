import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationService {
  final _dio = ApiClient().dio;

  Future<List<NotificationModel>> getNotifications() async {
    final res = await _dio.get('/notifications/');
    return (res.data as List).map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/notifications/unread-count');
    return res.data['count'] as int;
  }

  Future<void> markRead(int id) async {
    await _dio.put('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.put('/notifications/read-all');
  }
}

final notificationServiceProvider = Provider((_) => NotificationService());

final notificationsProvider = FutureProvider.autoDispose<List<NotificationModel>>((ref) async {
  return ref.watch(notificationServiceProvider).getNotifications();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(notificationServiceProvider).getUnreadCount();
});
