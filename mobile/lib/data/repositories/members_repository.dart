import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/member.dart';

class MembersPage {
  final List<Member> items;
  final int total;
  final int page;
  final bool hasMore;
  MembersPage({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });
}

class MembersFilters {
  final List<String> governorates;
  final List<String> ranks;
  final List<String> specializations;
  MembersFilters({
    required this.governorates,
    required this.ranks,
    required this.specializations,
  });
}

class MembersRepository {
  final DioClient client;
  MembersRepository(this.client);

  Future<MembersPage> list({
    int page = 1,
    int limit = 20,
    String? q,
    String? governorate,
    String? judicialRank,
    String? specialization,
  }) async {
    final res = await client.dio.get(
      ApiConstants.members,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (q != null && q.isNotEmpty) 'q': q,
        if (governorate != null && governorate.isNotEmpty) 'governorate': governorate,
        if (judicialRank != null && judicialRank.isNotEmpty) 'judicialRank': judicialRank,
        if (specialization != null && specialization.isNotEmpty) 'specialization': specialization,
      },
    );
    final items = (res.data['items'] as List)
        .map((e) => Member.fromJson(e as Map<String, dynamic>))
        .toList();
    return MembersPage(
      items: items,
      total: res.data['total'] as int,
      page: res.data['page'] as int,
      hasMore: res.data['hasMore'] as bool? ?? false,
    );
  }

  Future<Member> getOne(String id) async {
    final res = await client.dio.get('${ApiConstants.members}/$id');
    return Member.fromJson(res.data['member'] as Map<String, dynamic>);
  }

  Future<Member> getMine() async {
    final res = await client.dio.get(ApiConstants.myMember);
    return Member.fromJson(res.data['member'] as Map<String, dynamic>);
  }

  Future<Member> updateMine(Map<String, dynamic> data) async {
    final res = await client.dio.patch(ApiConstants.myMember, data: data);
    return Member.fromJson(res.data['member'] as Map<String, dynamic>);
  }

  Future<Member> uploadPhoto(String filePath) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    final res = await client.dio.post(ApiConstants.myPhoto, data: form);
    return Member.fromJson(res.data['member'] as Map<String, dynamic>);
  }

  Future<MembersFilters> filters() async {
    final res = await client.dio.get(ApiConstants.filters);
    return MembersFilters(
      governorates: (res.data['governorates'] as List).cast<String>(),
      ranks: (res.data['ranks'] as List).cast<String>(),
      specializations: (res.data['specializations'] as List).cast<String>(),
    );
  }
}
