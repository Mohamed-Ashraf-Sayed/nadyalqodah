class NewsItem {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? category;
  final DateTime publishedAt;
  final String? authorEmail;

  NewsItem({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.category,
    required this.publishedAt,
    this.authorEmail,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return NewsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['imageUrl'] as String?,
      category: json['category'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      authorEmail: author?['email'] as String?,
    );
  }
}
