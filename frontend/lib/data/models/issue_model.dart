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
  final String issueType;
  final String? areaName;
  final int? areaId;
  final String? suggestedServiceName;
  final String? suggestionNote;

  const IssueModel({
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
    this.issueType = 'GENERAL',
    this.areaName,
    this.areaId,
    this.suggestedServiceName,
    this.suggestionNote,
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
      createdAt: json['createdAt']?.toString(),
      issueType: json['issueType'] ?? 'GENERAL',
      areaName: json['areaName'],
      areaId: json['areaId'],
      suggestedServiceName: json['suggestedServiceName'],
      suggestionNote: json['suggestionNote'],
    );
  }

  bool get hasServiceSuggestion {
    if (issueType == 'SERVICE_SUGGESTION') return true;
    return (suggestedServiceName ?? '').trim().isNotEmpty ||
        (suggestionNote ?? '').trim().isNotEmpty;
  }

  IssueServiceSuggestion? get serviceSuggestion {
    if (!hasServiceSuggestion) return null;
    return IssueServiceSuggestion(
      serviceName: (suggestedServiceName ?? '').trim(),
      note: (suggestionNote ?? '').trim(),
      areaId: areaId,
      areaName: areaName,
    );
  }

  String get cleanDescription => (description ?? '').trim();
}

class IssueServiceSuggestion {
  final String serviceName;
  final String note;
  final int? areaId;
  final String? areaName;

  const IssueServiceSuggestion({
    required this.serviceName,
    required this.note,
    this.areaId,
    this.areaName,
  });
}
