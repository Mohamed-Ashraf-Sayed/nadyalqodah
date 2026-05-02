enum UserRole { member, admin, superAdmin }

enum UserStatus { pending, approved, rejected, suspended }

UserRole _parseRole(String? s) {
  switch (s) {
    case 'ADMIN':
      return UserRole.admin;
    case 'SUPER_ADMIN':
      return UserRole.superAdmin;
    default:
      return UserRole.member;
  }
}

UserStatus _parseStatus(String? s) {
  switch (s) {
    case 'APPROVED':
      return UserStatus.approved;
    case 'REJECTED':
      return UserStatus.rejected;
    case 'SUSPENDED':
      return UserStatus.suspended;
    default:
      return UserStatus.pending;
  }
}

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final UserStatus status;
  final bool emailVerified;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.emailVerified = false,
  });

  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String,
        role: _parseRole(json['role'] as String?),
        status: _parseStatus(json['status'] as String?),
        emailVerified: json['emailVerified'] as bool? ?? false,
      );
}
