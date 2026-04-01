class NotificationModel {
  final int notificationId;
  final String type;
  final String title;
  final String body;
  final String? refType;
  final int? refId;
  final bool isRead;
  final String? createdAt;
  final String? readAt;

  NotificationModel({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    this.refType,
    this.refId,
    required this.isRead,
    this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: _toInt(json['notificationId']),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      refType: json['refType']?.toString(),
      refId: json['refId'] == null ? null : _toInt(json['refId']),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt']?.toString(),
      readAt: json['readAt']?.toString(),
    );
  }

  NotificationModel copyWith({
    int? notificationId,
    String? type,
    String? title,
    String? body,
    String? refType,
    int? refId,
    bool? isRead,
    String? createdAt,
    String? readAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
