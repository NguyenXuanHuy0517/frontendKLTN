import 'package:flutter/material.dart';

import '../core/session/session_store.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  AuthProvider() {
    _syncFromSession();
    SessionStore.instance.addListener(_handleSessionChanged);
  }

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
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
    String accountType = 'TENANT',
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
        accountType: accountType,
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

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.resetPassword(token: token, newPassword: newPassword);
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

  void refreshSessionUser() {
    _syncFromSession();
    notifyListeners();
  }

  void _handleSessionChanged() {
    _syncFromSession();
    notifyListeners();
  }

  void _syncFromSession() {
    _user = SessionStore.instance.toUserModel();
  }

  String _parseError(dynamic error) {
    final message = error.toString();
    if (message.contains('401') || message.contains('403')) {
      return 'Email hoặc mật khẩu không đúng';
    }
    if (message.contains('400')) return 'Thông tin không hợp lệ';
    if (message.contains('SocketException') || message.contains('connection')) {
      return 'Không có kết nối mạng';
    }
    return 'Đã có lỗi xảy ra, vui lòng thử lại';
  }

  @override
  void dispose() {
    SessionStore.instance.removeListener(_handleSessionChanged);
    super.dispose();
  }
}
