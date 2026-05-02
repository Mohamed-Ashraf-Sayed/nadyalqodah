enum SuggestionType { suggestion, complaint }

enum SuggestionStatus { open, inProgress, resolved, closed }

extension SuggestionTypeX on SuggestionType {
  String get apiValue => this == SuggestionType.suggestion ? 'SUGGESTION' : 'COMPLAINT';
  String get label => this == SuggestionType.suggestion ? 'اقتراح' : 'شكوى';
}

extension SuggestionStatusX on SuggestionStatus {
  String get apiValue {
    switch (this) {
      case SuggestionStatus.open:
        return 'OPEN';
      case SuggestionStatus.inProgress:
        return 'IN_PROGRESS';
      case SuggestionStatus.resolved:
        return 'RESOLVED';
      case SuggestionStatus.closed:
        return 'CLOSED';
    }
  }

  String get label {
    switch (this) {
      case SuggestionStatus.open:
        return 'مفتوح';
      case SuggestionStatus.inProgress:
        return 'قيد المراجعة';
      case SuggestionStatus.resolved:
        return 'تم الحل';
      case SuggestionStatus.closed:
        return 'مغلق';
    }
  }
}

SuggestionType _parseType(String s) =>
    s == 'COMPLAINT' ? SuggestionType.complaint : SuggestionType.suggestion;

SuggestionStatus _parseStatus(String? s) {
  switch (s) {
    case 'IN_PROGRESS':
      return SuggestionStatus.inProgress;
    case 'RESOLVED':
      return SuggestionStatus.resolved;
    case 'CLOSED':
      return SuggestionStatus.closed;
    default:
      return SuggestionStatus.open;
  }
}

class Suggestion {
  final String id;
  final SuggestionType type;
  final String subject;
  final String body;
  final SuggestionStatus status;
  final bool isAnonymous;
  final String? adminResponse;
  final DateTime? respondedAt;
  final String? userEmail;
  final DateTime createdAt;

  Suggestion({
    required this.id,
    required this.type,
    required this.subject,
    required this.body,
    required this.status,
    required this.isAnonymous,
    this.adminResponse,
    this.respondedAt,
    this.userEmail,
    required this.createdAt,
  });

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return Suggestion(
      id: json['id'] as String,
      type: _parseType(json['type'] as String),
      subject: json['subject'] as String,
      body: json['body'] as String,
      status: _parseStatus(json['status'] as String?),
      isAnonymous: json['isAnonymous'] as bool? ?? false,
      adminResponse: json['adminResponse'] as String?,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      userEmail: user?['email'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get hasResponse => adminResponse != null && adminResponse!.isNotEmpty;
}
