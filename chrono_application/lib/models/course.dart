/// Defines the data structure for a single academic course.
class Course {
  final String id;
  final String title;
  final String code;
  final String time;
  final String days;
  final String imageAsset; // Mock image asset path

  Course({
    required this.id,
    required this.title,
    required this.code,
    required this.time,
    required this.days,
    required this.imageAsset,
  });

  /// Factory method to create a Course object from a map (e.g., from a database or PDF extraction).
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      title: map['title'] as String,
      code: map['code'] as String,
      time: map['time'] as String,
      days: map['days'] as String,
      // Provide a default or use a dynamic logic for the image
      imageAsset:
          map['imageAsset'] as String? ?? 'assets/images/default_class.png',
    );
  }

  /// Converts the Course object to a map (e.g., for saving to a database).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'code': code,
      'time': time,
      'days': days,
      'imageAsset': imageAsset,
    };
  }
}
