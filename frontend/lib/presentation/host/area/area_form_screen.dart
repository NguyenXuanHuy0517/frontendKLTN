import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/area_model.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/auth_provider.dart';

class AreaFormScreen extends StatefulWidget {
  final int? areaId;
  const AreaFormScreen({super.key, this.areaId});

  @override
  State<AreaFormScreen> createState() => _AreaFormScreenState();
}

class _AreaFormScreenState extends State<AreaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _loading = false;
  bool get _isEdit => widget.areaId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _prefill();
  }

  void _prefill() {
    final areas = context.read<AreaProvider>().areas;
    final area = areas.firstWhere(
      (a) => a.areaId == widget.areaId,
      orElse: () => AreaModel(
        areaId: 0,
        areaName: '',
        address: '',
        totalRooms: 0,
        availableRooms: 0,
        rentedRooms: 0,
        maintenanceRooms: 0,
      ),
    );
    _nameCtrl.text = area.areaName;
    _addressCtrl.text = area.address;
    _wardCtrl.text = area.ward ?? '';
    _districtCtrl.text = area.district ?? '';
    _cityCtrl.text = area.city ?? '';
    _descCtrl.text = area.description ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _wardCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final data = {
      'areaName': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'ward': _wardCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
    };

    final provider = context.read<AreaProvider>();
    bool ok;

    if (_isEdit) {
      ok = await provider.updateArea(widget.areaId!, data);
    } else {
      final hostId = await context.read<AuthProvider>().getUserId();
      ok = await provider.createArea(hostId!, data);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Cập nhật thành công' : 'Tạo khu trọ thành công',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Thao tác thất bại'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEdit ? 'Chỉnh sửa khu trọ' : 'Thêm khu trọ',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Tên khu trọ *',
                hint: 'Nhà trọ Minh Thành',
                controller: _nameCtrl,
                prefixIcon: Icons.location_city_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập tên khu trọ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Địa chỉ *',
                hint: '123 Đường ABC',
                controller: _addressCtrl,
                prefixIcon: Icons.place_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập địa chỉ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Phường/Xã',
                      hint: 'Phường 1',
                      controller: _wardCtrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Quận/Huyện',
                      hint: 'Quận 1',
                      controller: _districtCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Tỉnh/Thành phố',
                hint: 'TP. Hồ Chí Minh',
                controller: _cityCtrl,
                prefixIcon: Icons.map_outlined,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Mô tả',
                hint: 'Thông tin thêm về khu trọ...',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: _isEdit ? 'Lưu thay đổi' : 'Tạo khu trọ',
                onPressed: _submit,
                loading: _loading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
