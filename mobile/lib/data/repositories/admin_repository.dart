import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/admin_stats.dart';
import '../models/member.dart';

class PendingRequest {
  final String userId;
  final String? memberId;
  final String email;
  final String fullNameAr;
  final String judicialRank;
  final String currentCourt;
  final String mobile;
  final DateTime createdAt;

  PendingRequest({
    required this.userId,
    required this.memberId,
    required this.email,
    required this.fullNameAr,
    required this.judicialRank,
    required this.currentCourt,
    required this.mobile,
    required this.createdAt,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    final m = json['member'] as Map<String, dynamic>?;
    return PendingRequest(
      userId: json['id'] as String,
      memberId: m?['id'] as String?,
      email: json['email'] as String,
      fullNameAr: m?['fullNameAr'] as String? ?? '',
      judicialRank: m?['judicialRank'] as String? ?? '',
      currentCourt: m?['currentCourt'] as String? ?? '',
      mobile: m?['mobile'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class AdminRepository {
  final DioClient client;
  AdminRepository(this.client);

  Future<List<PendingRequest>> pending() async {
    final res = await client.dio.get(ApiConstants.adminPending);
    return (res.data['items'] as List)
        .map((e) => PendingRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approve(String userId) async {
    await client.dio.post('/admin/members/$userId/approve');
  }

  Future<void> reject(String userId, String? reason) async {
    await client.dio.post('/admin/members/$userId/reject', data: {'reason': reason});
  }

  Future<Member> getMember(String memberId) async {
    final res = await client.dio.get('${ApiConstants.members}/$memberId');
    return Member.fromJson(res.data['member'] as Map<String, dynamic>);
  }

  Future<Member> updateMember(String memberId, Map<String, dynamic> data) async {
    final res = await client.dio.patch('/admin/members/$memberId', data: data);
    return Member.fromJson(res.data['member'] as Map<String, dynamic>);
  }

  Future<void> broadcast({required String title, required String body}) async {
    await client.dio.post(ApiConstants.adminBroadcast, data: {
      'title': title,
      'body': body,
    });
  }

  Future<AdminStats> stats() async {
    final res = await client.dio.get(ApiConstants.adminStats);
    return AdminStats.fromJson(res.data as Map<String, dynamic>);
  }
}
