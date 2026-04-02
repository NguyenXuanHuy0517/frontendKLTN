import '../models/user_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/session/session_store.dart';

class AuthService {
  final _dio = ApiClient.instance.authDio;

  Future<UserModel> login(String email, String password) async {
    final res = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final user = UserModel.fromJson(res.data['data']);
    await _saveUser(user);
    return user;
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String idCardNumber,
    String accountType = 'TENANT',
  }) async {
    final endpoint = accountType.toUpperCase() == 'HOST'
        ? ApiConstants.registerHost
        : ApiConstants.registerTenant;
    await _dio.post(
      endpoint,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'idCardNumber': idCardNumber,
      },
    );
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post(ApiConstants.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiConstants.resetPassword,
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<void> _saveUser(UserModel user) async {
    await SessionStore.instance.saveUser(user);
  }

  Future<void> logout() async {
    await SessionStore.instance.clear();
  }

  Future<bool> isLoggedIn() async => SessionStore.instance.isLoggedIn;

  Future<String?> getRole() async => SessionStore.instance.role;

  Future<int?> getUserId() async => SessionStore.instance.userId;

  Future<bool> getRequiresRentalJoin() async =>
      SessionStore.instance.requiresRentalJoin;
}
