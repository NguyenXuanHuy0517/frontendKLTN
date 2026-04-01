import '../../core/constants/api_constants.dart';
import '../models/issue_model.dart';
import 'api_client.dart';

class IssueService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<IssueModel>> getIssues(int hostId, {String? issueType}) async {
    final queryParameters = <String, dynamic>{'hostId': hostId};
    if ((issueType ?? '').trim().isNotEmpty) {
      queryParameters['issueType'] = issueType;
    }

    final res = await _dio.get(
      ApiConstants.issues,
      queryParameters: queryParameters,
    );
    return (res.data['data'] as List)
        .map((item) => IssueModel.fromJson(item))
        .toList();
  }

  Future<IssueModel> getIssueDetail(int issueId) async {
    final res = await _dio.get('${ApiConstants.issues}/$issueId');
    return IssueModel.fromJson(res.data['data']);
  }

  Future<void> updateStatus(
    int issueId,
    String status,
    String? handlerNote,
  ) async {
    await _dio.patch(
      '${ApiConstants.issues}/$issueId/status',
      data: {'status': status, 'handlerNote': handlerNote},
    );
  }
}
