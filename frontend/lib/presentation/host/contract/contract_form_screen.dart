import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/contract_provider.dart';
import '../../../providers/deposit_provider.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/tenant_provider.dart';

class ContractFormScreen extends StatefulWidget {
  const ContractFormScreen({super.key});

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _elecCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  final _penaltyCtrl = TextEditingController();

  int? _selectedTenantId;
  int? _selectedRoomId;
  int? _selectedDepositId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hostId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;
    context.read<TenantProvider>().fetchTenants(hostId!);
    context.read<RoomProvider>().fetchRooms(hostId);
    context.read<DepositProvider>().fetchDeposits(hostId);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _elecCtrl.dispose();
    _waterCtrl.dispose();
    _penaltyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTenantId == null) {
      _showError('Vui lòng chọn người thuê');
      return;
    }
    if (_selectedRoomId == null) {
      _showError('Vui lòng chọn phòng');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _showError('Vui lòng chọn ngày bắt đầu và kết thúc');
      return;
    }

    setState(() => _loading = true);

    final data = {
      'tenantId': _selectedTenantId,
      'roomId': _selectedRoomId,
      'depositId': _selectedDepositId,
      'startDate': _startDate!.toIso8601String().split('T')[0],
      'endDate': _endDate!.toIso8601String().split('T')[0],
      'actualRentPrice': double.tryParse(_priceCtrl.text) ?? 0,
      'elecPriceOverride': _elecCtrl.text.isNotEmpty
          ? double.tryParse(_elecCtrl.text)
          : null,
      'waterPriceOverride': _waterCtrl.text.isNotEmpty
          ? double.tryParse(_waterCtrl.text)
          : null,
      'penaltyTerms': _penaltyCtrl.text.trim(),
    };

    final provider = context.read<ContractProvider>();
    final ok = await provider.createContract(data);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tạo hợp đồng thành công'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.pop();
    } else {
      _showError(provider.error ?? 'Thao tác thất bại');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final tenants = context.watch<TenantProvider>().tenants;
    final rooms = context.watch<RoomProvider>()
        .rooms
        .where((r) => r.status == 'AVAILABLE' || r.status == 'DEPOSITED')
        .toList();
    final deposits = context.watch<DepositProvider>()
        .deposits
        .where((d) => d.status == 'CONFIRMED')
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Tạo hợp đồng',
            style: AppTextStyles.h3.copyWith(color: fg)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Người thuê
              _DropdownField(
                label: 'Người thuê *',
                hint: 'Chọn người thuê',
                value: _selectedTenantId,
                items: tenants
                    .map((t) => DropdownMenuItem(
                  value: t.userId,
                  child: Text(
                      '${t.fullName} — ${t.phoneNumber}'),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTenantId = v),
                isDark: isDark,
                cardColor: cardColor,
                border: border,
                subtext: subtext,
                fg: fg,
              ),
              const SizedBox(height: 16),

              // Phòng
              _DropdownField(
                label: 'Phòng *',
                hint: 'Chọn phòng',
                value: _selectedRoomId,
                items: rooms
                    .map((r) => DropdownMenuItem(
                  value: r.roomId,
                  child:
                  Text('${r.roomCode} — ${r.areaName}'),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedRoomId = v),
                isDark: isDark,
                cardColor: cardColor,
                border: border,
                subtext: subtext,
                fg: fg,
              ),
              const SizedBox(height: 16),

              // Đặt cọc (optional)
              _DropdownField(
                label: 'Đặt cọc liên kết (tuỳ chọn)',
                hint: 'Chọn đặt cọc',
                value: _selectedDepositId,
                items: deposits
                    .map((d) => DropdownMenuItem(
                  value: d.depositId,
                  child: Text(
                      '${d.tenantName} — Phòng ${d.roomCode}'),
                ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedDepositId = v),
                isDark: isDark,
                cardColor: cardColor,
                border: border,
                subtext: subtext,
                fg: fg,
              ),
              const SizedBox(height: 16),

              // Ngày bắt đầu / kết thúc
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Ngày bắt đầu *',
                      value: _startDate != null
                          ? AppDateUtils.formatDate(
                          _startDate!.toIso8601String())
                          : null,
                      onTap: () => _pickDate(true),
                      isDark: isDark,
                      subtext: subtext,
                      fg: fg,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Ngày kết thúc *',
                      value: _endDate != null
                          ? AppDateUtils.formatDate(
                          _endDate!.toIso8601String())
                          : null,
                      onTap: () => _pickDate(false),
                      isDark: isDark,
                      subtext: subtext,
                      fg: fg,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Giá thuê thực tế (₫/tháng) *',
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
                      label: 'Giá điện riêng (₫/kWh)',
                      hint: 'Để trống = dùng giá phòng',
                      controller: _elecCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Giá nước riêng (₫/m³)',
                      hint: 'Để trống = dùng giá phòng',
                      controller: _waterCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Điều khoản phạt',
                hint: 'Phạt 1 tháng tiền thuê nếu phá hợp đồng...',
                controller: _penaltyCtrl,
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              AppButton(
                label: 'Tạo hợp đồng',
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

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final bool isDark;
  final Color cardColor;
  final Color border;
  final Color subtext;
  final Color fg;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
    required this.cardColor,
    required this.border,
    required this.subtext,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.label.copyWith(color: subtext)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: cardColor,
              hint: Text(hint,
                  style: AppTextStyles.body.copyWith(color: subtext)),
              style: AppTextStyles.body.copyWith(color: fg),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool isDark;
  final Color subtext;
  final Color fg;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.isDark,
    required this.subtext,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.label.copyWith(color: subtext)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: subtext),
                const SizedBox(width: 8),
                Text(
                  value ?? 'Chọn ngày',
                  style: AppTextStyles.body.copyWith(
                    color: value != null ? fg : subtext,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}