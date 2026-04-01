import 'package:flutter/material.dart';

import '../data/models/admin_room_audit_model.dart';
import '../data/services/admin_service.dart';

class AdminRoomProvider extends ChangeNotifier {
  final _service = AdminService();

  List<AdminRoomAuditModel> _rooms = [];
  List<AdminRoomAuditModel> _missingInvoiceRooms = [];
  bool _loading = false;
  String? _error;

  List<AdminRoomAuditModel> get rooms => _rooms;
  List<AdminRoomAuditModel> get missingInvoiceRooms => _missingInvoiceRooms;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchRoomAudit() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getRooms(),
        _service.getRoomsWithoutInvoice(),
      ]);
      _rooms = results[0];
      _missingInvoiceRooms = results[1];
    } catch (_) {
      _error = 'Khong tai duoc du lieu kiem soat phong';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
