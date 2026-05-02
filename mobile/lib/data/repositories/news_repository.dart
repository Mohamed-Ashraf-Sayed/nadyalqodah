import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/news.dart';

class NewsRepository {
  final DioClient client;
  NewsRepository(this.client);

  Future<List<NewsItem>> list({int page = 1, int limit = 20}) async {
    final res = await client.dio.get(
      ApiConstants.news,
      queryParameters: {'page': page, 'limit': limit},
    );
    return (res.data['items'] as List)
        .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NewsItem> getOne(String id) async {
    final res = await client.dio.get('${ApiConstants.news}/$id');
    return NewsItem.fromJson(res.data['news'] as Map<String, dynamic>);
  }

  Future<NewsItem> create({
    required String title,
    required String body,
    String? imageUrl,
    String? category,
    bool notifyAll = true,
  }) async {
    final res = await client.dio.post(
      ApiConstants.news,
      data: {
        'title': title,
        'body': body,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (category != null) 'category': category,
        'notifyAll': notifyAll,
      },
    );
    return NewsItem.fromJson(res.data['news'] as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await client.dio.delete('${ApiConstants.news}/$id');
  }
}
