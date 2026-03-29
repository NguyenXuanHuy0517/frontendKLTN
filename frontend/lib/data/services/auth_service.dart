import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/storage_keys.dart';

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
  }) async {
    await _dio.post(ApiConstants.register, data: {
      'fullName': fullName,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'idCardNumber': idCardNumber,
    });
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.token, user.token);
    await prefs.setInt(StorageKeys.userId, user.userId);
    await prefs.setString(StorageKeys.role, user.role);
    await prefs.setString(StorageKeys.fullName, user.fullName);
    await prefs.setString(StorageKeys.email, user.email);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.token) != null;
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.role);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(StorageKeys.userId);
  }
}