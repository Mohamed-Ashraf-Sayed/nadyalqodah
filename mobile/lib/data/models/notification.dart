class AppNotification {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        data: json['data'] as Map<String, dynamic>?,
        readAt: json['readAt'] != null
            ? DateTime.tryParse(json['readAt'].toString())
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
