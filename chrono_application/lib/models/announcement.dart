class Announcement {
  final int id;
  final String title;
  final String content;
  final DateTime publishedAt;
  final String authorName;

  // Removed: final String? imagePath;
  // Removed: final String? profileImg;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAt,
    required this.authorName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      // Ensure we handle parsing the ISO date string correctly
      publishedAt: DateTime.parse(json['published_at'] as String),
      authorName: json['author_name'] as String,

      // Removed these properties from the JSON mapping:
      // imagePath: json['image_path'] as String?,
      // profileImg: json['profile_img'] as String?,
    );
  }
}
