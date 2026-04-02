import '../models/area_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class AreaService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<AreaModel>> getAreas(int hostId) async {
    final res = await _dio.get(
      ApiConstants.areas,
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => AreaModel.fromJson(e))
        .toList();
  }

  Future<AreaModel> createArea(int hostId, Map<String, dynamic> data) async {
    final res = await _dio.post(
      ApiConstants.areas,
      queryParameters: {'hostId': hostId},
      data: data,
    );
    return AreaModel.fromJson(res.data['data']);
  }

  Future<AreaModel> updateArea(int areaId, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.areas}/$areaId', data: data);
    return AreaModel.fromJson(res.data['data']);
  }
}
