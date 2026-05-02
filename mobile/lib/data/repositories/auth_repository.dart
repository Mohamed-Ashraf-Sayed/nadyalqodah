import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/user.dart';
import '../models/member.dart';

class AuthRepository {
  final DioClient client;
  final TokenStorage tokens;
  AuthRepository(this.client, this.tokens);

  Future<({AppUser user, String? message})> register(Map<String, dynamic> body) async {
    final res = await client.dio.post(ApiConstants.register, data: body);
    return (
      user: AppUser.fromJson(res.data['user'] as Map<String, dynamic>),
      message: res.data['message'] as String?,
    );
  }

  Future<AppUser> login(String email, String password) async {
    final res = await client.dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final access = res.data['accessToken'] as String;
    final refresh = res.data['refreshToken'] as String;
    await tokens.save(access, refresh);
    return AppUser.fromJson(res.data['user'] as Map<String, dynamic>);
  }

  Future<void> serverLogout() async {
    final refresh = await tokens.getRefresh();
    if (refresh != null) {
      try {
        await client.dio.post(ApiConstants.logout, data: {'refreshToken': refresh});
      } catch (_) {}
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await client.dio.post(ApiConstants.passwordRequest, data: {'email': email});
  }

  Future<void> verifyResetCode(String email, String code) async {
    await client.dio.post(
      ApiConstants.passwordVerify,
      data: {'email': email, 'code': code},
    );
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    await client.dio.post(
      ApiConstants.passwordReset,
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  Future<void> requestEmailVerification() async {
    await client.dio.post(ApiConstants.emailRequestCode);
  }

  Future<void> confirmEmail(String code) async {
    await client.dio.post(ApiConstants.emailConfirm, data: {'code': code});
  }

  Future<void> deleteAccount(String password) async {
    await client.dio.delete(ApiConstants.me, data: {'password': password});
    await tokens.clear();
  }

  Future<({AppUser user, Member? member})> me() async {
    final res = await client.dio.get(ApiConstants.me);
    final memberJson = res.data['member'] as Map<String, dynamic>?;
    return (
      user: AppUser.fromJson(res.data['user'] as Map<String, dynamic>),
      member: memberJson != null ? Member.fromJson(memberJson) : null,
    );
  }

  Future<void> logout() => tokens.clear();

  String? extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return null;
  }
}
