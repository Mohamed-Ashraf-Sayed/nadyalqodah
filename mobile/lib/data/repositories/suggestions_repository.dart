import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/suggestion.dart';

class SuggestionsRepository {
  final DioClient client;
  SuggestionsRepository(this.client);

  Future<List<Suggestion>> listMine() async {
    final res = await client.dio.get(ApiConstants.mySuggestions);
    return (res.data['items'] as List)
        .map((e) => Suggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Suggestion>> listAll({String? status}) async {
    final res = await client.dio.get(
      ApiConstants.suggestions,
      queryParameters: status != null ? {'status': status} : null,
    );
    return (res.data['items'] as List)
        .map((e) => Suggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Suggestion> create({
    required SuggestionType type,
    required String subject,
    required String body,
    bool isAnonymous = false,
  }) async {
    final res = await client.dio.post(ApiConstants.suggestions, data: {
      'type': type.apiValue,
      'subject': subject,
      'body': body,
      'isAnonymous': isAnonymous,
    });
    return Suggestion.fromJson(res.data['suggestion'] as Map<String, dynamic>);
  }

  Future<Suggestion> respond({
    required String id,
    String? response,
    SuggestionStatus? status,
  }) async {
    final res = await client.dio.post(
      '${ApiConstants.suggestions}/$id/respond',
      data: {
        if (response != null) 'response': response,
        if (status != null) 'status': status.apiValue,
      },
    );
    return Suggestion.fromJson(res.data['suggestion'] as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await client.dio.delete('${ApiConstants.suggestions}/$id');
  }
}
