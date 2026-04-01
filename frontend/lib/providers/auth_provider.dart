import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String? v) {
    _error = v;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      _user = await _service.login(email, password);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String idCardNumber,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.register(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        idCardNumber: idCardNumber,
      );
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.forgotPassword(email);
      return true;
    } catch (e) {
      _setError(_parseError(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  Future<String?> checkAuth() async {
    final loggedIn = await _service.isLoggedIn();
    if (!loggedIn) return null;
    return _service.getRole();
  }

  Future<int?> getUserId() => _service.getUserId();

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401') || msg.contains('403')) return 'Email hoặc mật khẩu không đúng';
    if (msg.contains('400')) return 'Thông tin không hợp lệ';
    if (msg.contains('SocketException') || msg.contains('connection')) return 'Không có kết nối mạng';
    return 'Đã có lỗi xảy ra, vui lòng thử lại';
  }
}