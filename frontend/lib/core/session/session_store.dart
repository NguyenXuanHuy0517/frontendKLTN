import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';
import '../constants/storage_keys.dart';

class SessionStore extends ChangeNotifier {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  String? _token;
  int? _userId;
  String? _role;
  String? _fullName;
  String? _email;
  bool _requiresRentalJoin = false;
  bool _initialized = false;

  String? get token => _token;
  int? get userId => _userId;
  String? get role => _role;
  String? get fullName => _fullName;
  String? get email => _email;
  bool get requiresRentalJoin => _requiresRentalJoin;
  bool get isLoggedIn => (_token ?? '').isNotEmpty;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _apply(
      token: prefs.getString(StorageKeys.token),
      userId: prefs.getInt(StorageKeys.userId),
      role: prefs.getString(StorageKeys.role),
      fullName: prefs.getString(StorageKeys.fullName),
      email: prefs.getString(StorageKeys.email),
      requiresRentalJoin:
          prefs.getBool(StorageKeys.requiresRentalJoin) ?? false,
      notify: false,
    );
    _initialized = true;
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.token, user.token);
    await prefs.setInt(StorageKeys.userId, user.userId);
    await prefs.setString(StorageKeys.role, user.role);
    await prefs.setString(StorageKeys.fullName, user.fullName);
    await prefs.setString(StorageKeys.email, user.email);
    await prefs.setBool(
      StorageKeys.requiresRentalJoin,
      user.requiresRentalJoin,
    );
    _apply(
      token: user.token,
      userId: user.userId,
      role: user.role,
      fullName: user.fullName,
      email: user.email,
      requiresRentalJoin: user.requiresRentalJoin,
    );
  }

  Future<void> setRequiresRentalJoin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.requiresRentalJoin, value);
    _apply(
      token: _token,
      userId: _userId,
      role: _role,
      fullName: _fullName,
      email: _email,
      requiresRentalJoin: value,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _apply(
      token: null,
      userId: null,
      role: null,
      fullName: null,
      email: null,
      requiresRentalJoin: false,
    );
  }

  void updateProfile({String? fullName, String? email}) {
    SharedPreferences.getInstance().then((prefs) async {
      if (fullName != null) {
        await prefs.setString(StorageKeys.fullName, fullName);
      }
      if (email != null) {
        await prefs.setString(StorageKeys.email, email);
      }
    });
    _apply(
      token: _token,
      userId: _userId,
      role: _role,
      fullName: fullName ?? _fullName,
      email: email ?? _email,
      requiresRentalJoin: _requiresRentalJoin,
    );
  }

  UserModel? toUserModel() {
    if (!isLoggedIn || _userId == null || _role == null) return null;
    return UserModel(
      userId: _userId!,
      fullName: _fullName ?? '',
      email: _email ?? '',
      role: _role!,
      token: _token!,
      requiresRentalJoin: _requiresRentalJoin,
    );
  }

  void _apply({
    required String? token,
    required int? userId,
    required String? role,
    required String? fullName,
    required String? email,
    required bool requiresRentalJoin,
    bool notify = true,
  }) {
    final changed =
        token != _token ||
        userId != _userId ||
        role != _role ||
        fullName != _fullName ||
        email != _email ||
        requiresRentalJoin != _requiresRentalJoin;
    _token = token;
    _userId = userId;
    _role = role;
    _fullName = fullName;
    _email = email;
    _requiresRentalJoin = requiresRentalJoin;
    if (notify && changed) notifyListeners();
  }
}
