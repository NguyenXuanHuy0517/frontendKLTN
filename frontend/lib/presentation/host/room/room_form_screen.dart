import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/room_model.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';

class RoomFormScreen extends StatefulWidget {
  final int? roomId;
  final int? initialAreaId;

  const RoomFormScreen({super.key, this.roomId, this.initialAreaId});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _elecCtrl = TextEditingController(text: '3500');
  final _waterCtrl = TextEditingController(text: '15000');
  final _sizeCtrl = TextEditingController();
  final _floorCtrl = TextEditingController(text: '1');
  final _descCtrl = TextEditingController();

  int? _selectedAreaId;
  bool _loading = false;
  bool get _isEdit => widget.roomId != null;

  @override
  void initState() {
    super.initState();
    _selectedAreaId = widget.initialAreaId;
    _loadAreas();
    if (_isEdit) _prefill();
  }

  Future<void> _loadAreas() async {
    final authProvider = context.read<AuthProvider>();
    final areaProvider = context.read<AreaProvider>();
    final hostId = await authProvider.getUserId();
    if (hostId != null && mounted) {
      await areaProvider.fetchAreas(hostId);
      final areaIds = areaProvider.areas.map((a) => a.areaId);
      if (_selectedAreaId != null && !areaIds.contains(_selectedAreaId)) {
        setState(() => _selectedAreaId = null);
      }
    }
  }

  Future<void> _openCreateAreaFlow() async {
    final areaProvider = context.read<AreaProvider>();
    final previousAreaIds = areaProvider.areas
        .map((area) => area.areaId)
        .toSet();

    await context.push('/host/areas/new');
    if (!mounted) return;

    await _loadAreas();
    if (!mounted) return;

    final areas = areaProvider.areas;
    final newAreas = areas
        .where((area) => !previousAreaIds.contains(area.areaId))
        .toList();

    if (newAreas.length == 1) {
      final createdArea = newAreas.first;
      setState(() => _selectedAreaId = createdArea.areaId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm khu trọ "${createdArea.areaName}" và tự động chọn cho phòng này.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _prefill() {
    final rooms = context.read<RoomProvider>().rooms;
    final room = rooms.firstWhere(
      (r) => r.roomId == widget.roomId,
      orElse: () => RoomModel(
        roomId: 0,
        roomCode: '',
        basePrice: 0,
        elecPrice: 3500,
        waterPrice: 15000,
        status: 'AVAILABLE',
        areaId: 0,
        areaName: '',
      ),
    );
    _codeCtrl.text = room.roomCode;
    _priceCtrl.text = room.basePrice.toStringAsFixed(0);
    _elecCtrl.text = room.elecPrice.toStringAsFixed(0);
    _waterCtrl.text = room.waterPrice.toStringAsFixed(0);
    _sizeCtrl.text = room.areaSize?.toStringAsFixed(0) ?? '';
    _floorCtrl.text = '${room.floor ?? 1}';
    _descCtrl.text = room.description ?? '';
    _selectedAreaId = room.areaId;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _priceCtrl.dispose();
    _elecCtrl.dispose();
    _waterCtrl.dispose();
    _sizeCtrl.dispose();
    _floorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAreaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn khu trọ')));
      return;
    }
    setState(() => _loading = true);

    final data = {
      'areaId': _selectedAreaId,
      'roomCode': _codeCtrl.text.trim(),
      'basePrice': double.tryParse(_priceCtrl.text) ?? 0,
      'elecPrice': double.tryParse(_elecCtrl.text) ?? 3500,
      'waterPrice': double.tryParse(_waterCtrl.text) ?? 15000,
      'areaSize': double.tryParse(_sizeCtrl.text),
      'floor': int.tryParse(_floorCtrl.text) ?? 1,
      'description': _descCtrl.text.trim(),
    };

    final provider = context.read<RoomProvider>();
    final bool ok;

    if (_isEdit) {
      ok = await provider.updateRoom(widget.roomId!, data);
    } else {
      ok = await provider.createRoom(data);
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Cập nhật phòng thành công' : 'Tạo phòng thành công',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.pop();
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
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final areas = context.watch<AreaProvider>().areas;
    final hasAreas = areas.isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isEdit ? 'Chỉnh sửa phòng' : 'Thêm phòng',
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
              // Khu trọ dropdown
              Text(
                'Khu trọ *',
                style: AppTextStyles.label.copyWith(color: subtext),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedAreaId,
                    isExpanded: true,
                    dropdownColor: cardColor,
                    hint: Text(
                      'Chọn khu trọ',
                      style: AppTextStyles.body.copyWith(color: subtext),
                    ),
                    style: AppTextStyles.body.copyWith(color: fg),
                    items: areas
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.areaId,
                            child: Text(a.areaName),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAreaId = v),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!hasAreas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Bạn cần tạo khu trọ trước khi tạo phòng.',
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openCreateAreaFlow,
                  icon: const Icon(
                    Icons.add_home_work_outlined,
                    size: 18,
                    color: AppColors.accent,
                  ),
                  label: Text(
                    '+ Thêm khu trọ mới',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: 'Mã phòng *',
                hint: 'P101',
                controller: _codeCtrl,
                prefixIcon: Icons.meeting_room_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập mã phòng';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: 'Giá thuê (₫/tháng) *',
                hint: '3000000',
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money_rounded,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập giá thuê';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Giá điện (₫/kWh)',
                      hint: '3500',
                      controller: _elecCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Giá nước (₫/m³)',
                      hint: '15000',
                      controller: _waterCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Diện tích (m²)',
                      hint: '25',
                      controller: _sizeCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Tầng',
                      hint: '1',
                      controller: _floorCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              AppTextField(
                label: 'Mô tả',
                hint: 'Thông tin thêm về phòng...',
                controller: _descCtrl,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              AppButton(
                label: _isEdit ? 'Lưu thay đổi' : 'Tạo phòng',
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
