import '../../core/constants/api_constants.dart';
import '../models/issue_model.dart';
import '../models/paged_result.dart';
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

  Future<PagedResult<IssueModel>> getIssuesPage({
    required int hostId,
    String? status,
    String? issueType,
    String? search,
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    final res = await _dio.get(
      '${ApiConstants.issues}/paged',
      queryParameters: {
        'hostId': hostId,
        'page': page,
        'size': size,
        'sort': sort,
        if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
        if ((issueType ?? '').trim().isNotEmpty) 'issueType': issueType!.trim(),
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
    return PagedResult.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
      IssueModel.fromJson,
    );
  }

  Future<IssueModel> getIssueDetail(int issueId) async {
    final res = await _dio.get('${ApiConstants.issues}/$issueId');
    return IssueModel.fromJson(res.data['data']);
  }

  Future<PagedResult<IssueModel>> getTenantIssuesPage({
    required int userId,
    String? status,
    String? search,
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    final res = await ApiClient.instance.tenantDio.get(
      '${ApiConstants.tenantIssues}/paged',
      queryParameters: {
        'userId': userId,
        'page': page,
        'size': size,
        'sort': sort,
        if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
    return PagedResult.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
      IssueModel.fromJson,
    );
  }

  Future<IssueModel> getTenantIssueDetail(int userId, int issueId) async {
    final res = await ApiClient.instance.tenantDio.get(
      '${ApiConstants.tenantIssues}/$issueId',
      queryParameters: {'userId': userId},
    );
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
