import '../models/contract_model.dart';
import '../models/rental_join_preview_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class RentalJoinService {
  final _dio = ApiClient.instance.tenantDio;

  Future<RentalJoinPreviewModel> previewInvite(String inviteCode) async {
    final response = await _dio.post(
      ApiConstants.tenantRentalJoinPreview,
      data: {'inviteCode': inviteCode},
    );
    return RentalJoinPreviewModel.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  Future<ContractModel> claimInvite(String inviteCode) async {
    final response = await _dio.post(
      ApiConstants.tenantRentalJoinClaim,
      data: {'inviteCode': inviteCode},
    );
    return ContractModel.fromTenantJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }
}
