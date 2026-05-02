class ClubEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final String? imageUrl;
  final String? category;
  final DateTime startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;

  ClubEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    this.imageUrl,
    this.category,
    required this.startsAt,
    this.endsAt,
    required this.createdAt,
  });

  factory ClubEvent.fromJson(Map<String, dynamic> json) => ClubEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        location: json['location'] as String?,
        imageUrl: json['imageUrl'] as String?,
        category: json['category'] as String?,
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: json['endsAt'] != null
            ? DateTime.parse(json['endsAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  bool get isPast => startsAt.isBefore(DateTime.now());
  bool get isUpcoming => !isPast;
}
