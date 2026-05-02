class Contract {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String fileUrl;
  final int? fileSize;
  final String? uploadedByEmail;
  final DateTime createdAt;

  Contract({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.fileUrl,
    this.fileSize,
    this.uploadedByEmail,
    required this.createdAt,
  });

  factory Contract.fromJson(Map<String, dynamic> json) {
    final uploader = json['uploadedBy'] as Map<String, dynamic>?;
    return Contract(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      fileUrl: json['fileUrl'] as String,
      fileSize: json['fileSize'] as int?,
      uploadedByEmail: uploader?['email'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
