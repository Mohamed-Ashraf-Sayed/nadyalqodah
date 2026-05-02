import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/notification.dart';

class NotificationsRepository {
  final DioClient client;
  NotificationsRepository(this.client);

  Future<List<AppNotification>> list() async {
    final res = await client.dio.get(ApiConstants.notifications);
    return (res.data['items'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) async {
    await client.dio.patch('${ApiConstants.notifications}/$id/read');
  }

  Future<void> markAllRead() async {
    await client.dio.patch('${ApiConstants.notifications}/read-all');
  }

  Future<void> registerDevice(String token, String platform) async {
    await client.dio.post(ApiConstants.devices, data: {
      'token': token,
      'platform': platform,
    });
  }
}
