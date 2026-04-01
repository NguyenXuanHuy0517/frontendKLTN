import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
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

  @override
  void dispose() {
    _priceCtrl.dispose();
    _elecCtrl.dispose();
    _waterCtrl.dispose();
    _penaltyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final tenantProvider = context.read<TenantProvider>();
    final roomProvider = context.read<RoomProvider>();
    final depositProvider = context.read<DepositProvider>();
    final hostId = await authProvider.getUserId();
    if (!mounted || hostId == null) return;

    await tenantProvider.fetchTenants(hostId);
    await roomProvider.fetchRooms(hostId);
    await depositProvider.fetchDeposits(hostId);
    if (!mounted) return;

    final tenantIds = tenantProvider.tenants
        .map((tenant) => tenant.userId)
        .toSet();
    final roomIds = roomProvider.rooms.map((room) => room.roomId).toSet();
    final depositIds = depositProvider.deposits
        .map((deposit) => deposit.depositId)
        .toSet();

    final nextTenantId = tenantIds.contains(_selectedTenantId)
        ? _selectedTenantId
        : null;
    final nextRoomId = roomIds.contains(_selectedRoomId)
        ? _selectedRoomId
        : null;
    final nextDepositId = depositIds.contains(_selectedDepositId)
        ? _selectedDepositId
        : null;

    if (nextTenantId != _selectedTenantId ||
        nextRoomId != _selectedRoomId ||
        nextDepositId != _selectedDepositId) {
      setState(() {
        _selectedTenantId = nextTenantId;
        _selectedRoomId = nextRoomId;
        _selectedDepositId = nextDepositId;
      });
    }
  }

  Future<void> _openCreateTenantFlow() async {
    final tenantProvider = context.read<TenantProvider>();
    final previousTenantIds = tenantProvider.tenants
        .map((tenant) => tenant.userId)
        .toSet();

    await context.push('/host/tenants/new');
    if (!mounted) return;

    await _loadData();
    if (!mounted) return;

    final newTenants = tenantProvider.tenants
        .where((tenant) => !previousTenantIds.contains(tenant.userId))
        .toList();

    if (newTenants.length == 1) {
      final createdTenant = newTenants.first;
      setState(() => _selectedTenantId = createdTenant.userId);
      _showSuccess(
        'Da them nguoi thue "${createdTenant.fullName}" va tu dong chon cho hop dong nay.',
      );
    }
  }

  Future<void> _openCreateRoomFlow() async {
    final roomProvider = context.read<RoomProvider>();
    final previousRoomIds = roomProvider.rooms
        .map((room) => room.roomId)
        .toSet();

    await context.push('/host/rooms/new');
    if (!mounted) return;

    await _loadData();
    if (!mounted) return;

    final eligibleNewRooms = roomProvider.rooms
        .where(
          (room) =>
              !previousRoomIds.contains(room.roomId) &&
              (room.status == 'AVAILABLE' || room.status == 'DEPOSITED'),
        )
        .toList();

    if (eligibleNewRooms.length == 1) {
      final createdRoom = eligibleNewRooms.first;
      setState(() => _selectedRoomId = createdRoom.roomId);
      _showSuccess(
        'Da them phong "${createdRoom.roomCode}" va tu dong chon cho hop dong nay.',
      );
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTenantId == null) {
      _showError('Vui long chon nguoi thue');
      return;
    }
    if (_selectedRoomId == null) {
      _showError('Vui long chon phong');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _showError('Vui long chon ngay bat dau va ket thuc');
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
      _showSuccess('Tao hop dong thanh cong');
      Navigator.of(context).pop();
    } else {
      _showError(provider.error ?? 'Thao tac that bai');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final rooms = context
        .watch<RoomProvider>()
        .rooms
        .where(
          (room) => room.status == 'AVAILABLE' || room.status == 'DEPOSITED',
        )
        .toList();
    final deposits = context
        .watch<DepositProvider>()
        .deposits
        .where((deposit) => deposit.status == 'CONFIRMED')
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Tao hop dong',
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
              _DropdownField(
                label: 'Nguoi thue *',
                hint: 'Chon nguoi thue',
                value: _selectedTenantId,
                items: tenants
                    .map(
                      (tenant) => DropdownMenuItem(
                        value: tenant.userId,
                        child: Text(
                          '${tenant.fullName} - ${tenant.phoneNumber}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedTenantId = value),
                cardColor: cardColor,
                border: border,
                subtext: subtext,
                fg: fg,
              ),
              const SizedBox(height: 8),
              if (tenants.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Ban can tao nguoi thue truoc khi tao hop dong.',
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                  ),
                ),
              _InlineCreateAction(
                label: '+ Them nguoi thue moi',
                icon: Icons.person_add_alt_rounded,
                onPressed: _openCreateTenantFlow,
              ),
              const SizedBox(height: 16),
              _DropdownField(
                label: 'Phong *',
                hint: 'Chon phong',
                value: _selectedRoomId,
                items: rooms
                    .map(
                      (room) => DropdownMenuItem(
                        value: room.roomId,
                        child: Text('${room.roomCode} - ${room.areaName}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedRoomId = value),
                cardColor: cardColor,
                border: border,
                subtext: subtext,
                fg: fg,
              ),
              const SizedBox(height: 8),
              if (rooms.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Ban can tao phong trong truoc khi tao hop dong.',
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                  ),
                ),
              _InlineCreateAction(
                label: '+ Them phong moi',
                icon: Icons.add_business_outlined,
                onPressed: _openCreateRoomFlow,
              ),
              const SizedBox(height: 16),
              _DropdownField(
                label: 'Dat coc lien ket (tuy chon)',
                hint: 'Chon dat coc',
                value: _selectedDepositId,
                items: deposits
                    .map(
                      (deposit) => DropdownMenuItem(
                        value: deposit.depositId,
                        child: Text(
                          '${deposit.tenantName} - Phong ${deposit.roomCode}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedDepositId = value),
                cardColor: cardColor,
                border: border,
                subtext: subtext,
                fg: fg,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Ngay bat dau *',
                      value: _startDate != null
                          ? AppDateUtils.formatDate(
                              _startDate!.toIso8601String(),
                            )
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
                      label: 'Ngay ket thuc *',
                      value: _endDate != null
                          ? AppDateUtils.formatDate(_endDate!.toIso8601String())
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
                label: 'Gia thue thuc te (VND/thang) *',
                hint: '3000000',
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui long nhap gia thue';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Gia dien rieng (VND/kWh)',
                      hint: 'De trong = dung gia phong',
                      controller: _elecCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Gia nuoc rieng (VND/m3)',
                      hint: 'De trong = dung gia phong',
                      controller: _waterCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Dieu khoan phat',
                hint: 'Phat 1 thang tien thue neu pha hop dong...',
                controller: _penaltyCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Tao hop dong',
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

class _InlineCreateAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _InlineCreateAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: AppColors.accent),
        label: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        Text(label, style: AppTextStyles.label.copyWith(color: subtext)),
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
              hint: Text(
                hint,
                style: AppTextStyles.body.copyWith(color: subtext),
              ),
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
        Text(label, style: AppTextStyles.label.copyWith(color: subtext)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: subtext),
                const SizedBox(width: 8),
                Text(
                  value ?? 'Chon ngay',
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
