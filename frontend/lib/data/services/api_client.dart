import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/session/session_store.dart';

class ApiClient {
  static ApiClient? _instance;
  late final Dio _authDio;
  late final Dio _hostDio;
  late final Dio _tenantDio;
  late final Dio _adminDio;

  ApiClient._() {
    _authDio = _createDio(ApiConstants.baseAuthUrl);
    _hostDio = _createDio(ApiConstants.baseHostUrl);
    _tenantDio = _createDio(ApiConstants.baseTenantUrl);
    _adminDio = _createDio(ApiConstants.baseAdminUrl);
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get authDio => _authDio;
  Dio get hostDio => _hostDio;
  Dio get tenantDio => _tenantDio;
  Dio get adminDio => _adminDio;

  Dio _createDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = SessionStore.instance.token;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Xóa Content-Type khi upload file để Dio tự set multipart
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }

          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );

    return dio;
  }
}
