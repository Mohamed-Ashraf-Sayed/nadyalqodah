import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/event.dart';

class EventsRepository {
  final DioClient client;
  EventsRepository(this.client);

  Future<List<ClubEvent>> list({bool upcomingOnly = false}) async {
    final res = await client.dio.get(
      ApiConstants.events,
      queryParameters: upcomingOnly ? {'upcoming': 'true'} : null,
    );
    return (res.data['items'] as List)
        .map((e) => ClubEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ClubEvent> getOne(String id) async {
    final res = await client.dio.get('${ApiConstants.events}/$id');
    return ClubEvent.fromJson(res.data['event'] as Map<String, dynamic>);
  }

  Future<ClubEvent> create({
    required String title,
    String? description,
    String? location,
    String? category,
    required DateTime startsAt,
    DateTime? endsAt,
  }) async {
    final res = await client.dio.post(ApiConstants.events, data: {
      'title': title,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      if (category != null) 'category': category,
      'startsAt': startsAt.toIso8601String(),
      if (endsAt != null) 'endsAt': endsAt.toIso8601String(),
    });
    return ClubEvent.fromJson(res.data['event'] as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await client.dio.delete('${ApiConstants.events}/$id');
  }
}
