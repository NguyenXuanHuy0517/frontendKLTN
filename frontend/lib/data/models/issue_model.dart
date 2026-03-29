class IssueModel {
  final int issueId;
  final String title;
  final String? description;
  final String tenantName;
  final String roomCode;
  final String priority;
  final String status;
  final String? handlerNote;
  final int? rating;
  final String? tenantFeedback;
  final String? createdAt;

  IssueModel({
    required this.issueId,
    required this.title,
    this.description,
    required this.tenantName,
    required this.roomCode,
    required this.priority,
    required this.status,
    this.handlerNote,
    this.rating,
    this.tenantFeedback,
    this.createdAt,
  });

  factory IssueModel.fromJson(Map<String, dynamic> json) {
    return IssueModel(
      issueId: json['issueId'],
      title: json['title'] ?? '',
      description: json['description'],
      tenantName: json['tenantName'] ?? '',
      roomCode: json['roomCode'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
      status: json['status'] ?? 'OPEN',
      handlerNote: json['handlerNote'],
      rating: json['rating'],
      tenantFeedback: json['tenantFeedback'],
      createdAt: json['createdAt'],
    );
  }
}