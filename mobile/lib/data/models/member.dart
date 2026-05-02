class Member {
  final String id;
  final String fullNameAr;
  final String? fullNameEn;
  final String? photoUrl;
  final String judicialRank;
  final String currentCourt;

  final String mobile;
  final String? whatsapp;
  final String? emailSecondary;

  final DateTime? birthDate;
  final String? address;

  final DateTime? appointmentDate;
  final String? governorate;
  final String? specialization;
  final String? currentPosition;

  final String? userEmail;
  final String? userId;

  Member({
    required this.id,
    required this.fullNameAr,
    this.fullNameEn,
    this.photoUrl,
    required this.judicialRank,
    required this.currentCourt,
    required this.mobile,
    this.whatsapp,
    this.emailSecondary,
    this.birthDate,
    this.address,
    this.appointmentDate,
    this.governorate,
    this.specialization,
    this.currentPosition,
    this.userEmail,
    this.userId,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final user = json['user'] as Map<String, dynamic>?;
    return Member(
      id: json['id'] as String,
      fullNameAr: json['fullNameAr'] as String,
      fullNameEn: json['fullNameEn'] as String?,
      photoUrl: json['photoUrl'] as String?,
      judicialRank: json['judicialRank'] as String,
      currentCourt: json['currentCourt'] as String,
      mobile: json['mobile'] as String,
      whatsapp: json['whatsapp'] as String?,
      emailSecondary: json['emailSecondary'] as String?,
      birthDate: parse(json['birthDate']),
      address: json['address'] as String?,
      appointmentDate: parse(json['appointmentDate']),
      governorate: json['governorate'] as String?,
      specialization: json['specialization'] as String?,
      currentPosition: json['currentPosition'] as String?,
      userEmail: user?['email'] as String?,
      userId: user?['id'] as String?,
    );
  }
}
