class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['subject']?.toString() ?? 'تنبيه',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? json['sentDate']?.toString() ?? '',
      ),
    );
  }
}