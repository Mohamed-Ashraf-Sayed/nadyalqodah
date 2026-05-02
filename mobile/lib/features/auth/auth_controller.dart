import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../data/models/member.dart';
import '../../data/providers/providers.dart';

class AuthState {
  final bool loading;
  final AppUser? user;
  final Member? member;
  final String? error;
  final bool initialized;

  const AuthState({
    this.loading = false,
    this.user,
    this.member,
    this.error,
    this.initialized = false,
  });

  AuthState copyWith({
    bool? loading,
    AppUser? user,
    Member? member,
    String? error,
    bool? initialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      loading: loading ?? this.loading,
      user: clearUser ? null : (user ?? this.user),
      member: clearUser ? null : (member ?? this.member),
      error: clearError ? null : (error ?? this.error),
      initialized: initialized ?? this.initialized,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final Ref ref;
  AuthController(this.ref) : super(const AuthState());

  Future<void> bootstrap() async {
    final tokens = ref.read(tokenStorageProvider);
    final access = await tokens.getAccess();
    if (access == null) {
      state = state.copyWith(initialized: true);
      return;
    }
    try {
      final me = await ref.read(authRepositoryProvider).me();
      state = state.copyWith(user: me.user, member: me.member, initialized: true);
    } catch (e) {
      // Only clear tokens on auth failure (401), not on transient network errors
      final isUnauthorized = e.toString().contains('401');
      if (isUnauthorized) {
        await tokens.clear();
        state = state.copyWith(initialized: true, clearUser: true);
      } else {
        // Keep tokens, mark as initialized but without user.
        // User can retry by re-opening the app or pull-to-refresh.
        state = state.copyWith(initialized: true);
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).login(email, password);
      final me = await ref.read(authRepositoryProvider).me();
      state = state.copyWith(loading: false, user: me.user, member: me.member);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _extractError(e));
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> body) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final res = await ref.read(authRepositoryProvider).register(body);
      state = state.copyWith(loading: false, user: res.user);
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: _extractError(e));
      return false;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.serverLogout();
    await repo.logout();
    state = const AuthState(initialized: true);
  }

  /// Called by DioClient when refresh token fails permanently.
  /// Clears user state so router redirects to /login.
  void clearOnAuthFailure() {
    if (state.user != null) {
      state = const AuthState(initialized: true);
    }
  }

  Future<void> refreshMe() async {
    try {
      final me = await ref.read(authRepositoryProvider).me();
      state = state.copyWith(user: me.user, member: me.member);
    } catch (_) {}
  }

  String _extractError(Object e) {
    if (e is DioException) {
      // Network / timeout errors first
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'الاتصال بطيء. تأكد من الإنترنت وحاول تاني';
        case DioExceptionType.connectionError:
          return 'تعذر الاتصال بالخادم. راجع الإنترنت';
        case DioExceptionType.badCertificate:
          return 'مشكلة في شهادة الأمان';
        case DioExceptionType.cancel:
          return 'تم إلغاء الطلب';
        default:
          break;
      }

      final status = e.response?.statusCode;
      final data = e.response?.data;
      String? code;
      String? reason;
      List<dynamic>? details;
      if (data is Map) {
        code = data['error']?.toString();
        reason = data['reason']?.toString();
        if (data['details'] is List) {
          details = data['details'] as List;
        }
      }

      // Specific known codes
      switch (code) {
        case 'invalid_credentials':
          return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        case 'email_taken':
          return 'هذا البريد الإلكتروني مسجل بالفعل';
        case 'rejected':
          return reason != null && reason.isNotEmpty
              ? 'تم رفض طلبك: $reason'
              : 'تم رفض طلبك من إدارة النادي';
        case 'suspended':
          return 'الحساب معلق. تواصل مع إدارة النادي';
        case 'too_many_attempts':
          return 'محاولات كتيرة. استنى شوية وحاول تاني';
        case 'invalid_password':
          return 'كلمة المرور غير صحيحة';
        case 'invalid_code':
          return 'الكود غير صحيح أو منتهي الصلاحية';
        case 'token_reused':
        case 'invalid_token':
          return 'انتهت صلاحية الجلسة. سجل دخول مرة أخرى';
        case 'last_super_admin':
          return 'لا يمكن حذف آخر مدير عام';
        case 'validation_error':
          return _formatValidationDetails(details);
      }

      // HTTP-status-based fallbacks (don't assume 401 = bad credentials)
      if (status == 401) return 'انتهت صلاحية الجلسة. سجل دخول مرة أخرى';
      if (status == 403) return 'غير مسموح بهذا الإجراء';
      if (status == 404) return 'البيانات غير موجودة';
      if (status == 409) return 'البيانات موجودة بالفعل';
      if (status == 413) return 'حجم الملف كبير جدًا';
      if (status == 429) return 'محاولات كتيرة. استنى شوية وحاول تاني';
      if (status != null && status >= 500) {
        return 'مشكلة في الخادم. حاول بعد دقيقة';
      }
      if (status != null) {
        // Surface unknown codes with a distinct message
        if (code != null) return 'حدث خطأ: $code';
        return 'حدث خطأ ($status)';
      }
    }
    return 'حدث خطأ غير متوقع. حاول مرة أخرى';
  }

  String _formatValidationDetails(List<dynamic>? details) {
    if (details == null || details.isEmpty) return 'تأكد من البيانات المدخلة';

    final fieldLabels = <String, String>{
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'fullNameAr': 'الاسم الرباعي',
      'judicialRank': 'الدرجة الوظيفية',
      'currentCourt': 'المحكمة',
      'mobile': 'رقم الموبايل',
      'code': 'الكود',
      'newPassword': 'كلمة المرور الجديدة',
      'title': 'العنوان',
      'body': 'النص',
    };

    final msgLabels = <String, String>{
      'password_min_8': 'لازم 8 حروف على الأقل',
      'password_needs_letter': 'لازم تحتوي على حرف',
      'password_needs_number': 'لازم تحتوي على رقم',
      'full_name_must_be_4_words': 'لازم 4 أسماء على الأقل',
      'invalid_id': 'معرف غير صحيح',
    };

    final issues = details.take(3).map((d) {
      if (d is Map) {
        final field = fieldLabels[d['field']?.toString()] ?? d['field'];
        final msg = msgLabels[d['msg']?.toString()] ?? d['msg'];
        return '$field: $msg';
      }
      return d.toString();
    }).join('\n');

    return issues;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref));
