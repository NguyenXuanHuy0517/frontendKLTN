import '../models/issue_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class IssueService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<IssueModel>> getIssues(int hostId) async {
    final res = await _dio.get(
      ApiConstants.issues,
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => IssueModel.fromJson(e))
        .toList();
  }

  Future<IssueModel> getIssueDetail(int issueId) async {
    final res = await _dio.get('${ApiConstants.issues}/$issueId');
    return IssueModel.fromJson(res.data['data']);
  }

  Future<void> updateStatus(
      int issueId, String status, String? handlerNote) async {
    await _dio.patch(
      '${ApiConstants.issues}/$issueId/status',
      data: {'status': status, 'handlerNote': handlerNote},
    );
  }
}