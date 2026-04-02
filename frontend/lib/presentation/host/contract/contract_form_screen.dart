import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/contract_invitation_model.dart';
import '../../../data/models/room_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/contract_provider.dart';
import '../../../providers/room_provider.dart';

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

  int? _selectedRoomId;
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
    final hostId = await context.read<AuthProvider>().getUserId();
    if (!mounted || hostId == null) return;

    await context.read<RoomProvider>().fetchRooms(hostId);
    if (!mounted) return;

    final availableRooms = context
        .read<RoomProvider>()
        .rooms
        .where((room) => room.status == 'AVAILABLE')
        .toList();

    if (_selectedRoomId == null && availableRooms.length == 1) {
      _handleRoomChanged(availableRooms.first.roomId);
      return;
    }

    final roomIds = availableRooms.map((room) => room.roomId).toSet();
    if (_selectedRoomId != null && !roomIds.contains(_selectedRoomId)) {
      setState(() => _selectedRoomId = null);
    }
  }

  void _handleRoomChanged(int? roomId) {
    setState(() => _selectedRoomId = roomId);

    if (roomId == null) return;
    final room = _selectedRoom;
    if (room == null) return;

    _priceCtrl.text = _formatPrice(room.basePrice);
    _elecCtrl.text = _formatPrice(room.elecPrice);
    _waterCtrl.text = _formatPrice(room.waterPrice);
  }

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  RoomModel? get _selectedRoom {
    if (_selectedRoomId == null) return null;
    final rooms = context.read<RoomProvider>().rooms;
    for (final room in rooms) {
      if (room.roomId == _selectedRoomId) {
        return room;
      }
    }
    return null;
  }

  Future<void> _openCreateRoomFlow() async {
    final previousRoomIds = context
        .read<RoomProvider>()
        .rooms
        .map((room) => room.roomId)
        .toSet();

    await context.push('/host/rooms/new');
    if (!mounted) return;

    await _loadData();
    if (!mounted) return;

    final newAvailableRooms = context
        .read<RoomProvider>()
        .rooms
        .where(
          (room) =>
              !previousRoomIds.contains(room.roomId) &&
              room.status == 'AVAILABLE',
        )
        .toList();

    if (newAvailableRooms.length == 1) {
      _handleRoomChanged(newAvailableRooms.first.roomId);
      _showMessage('Da them phong moi va tu dong chon phong trong.');
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate =
        (isStart ? _startDate : _endDate) ??
        DateTime.now().add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null) {
      _showMessage('Vui long chon phong trong', isError: true);
      return;
    }
    if (_startDate == null || _endDate == null) {
      _showMessage(
        'Vui long chon ngay bat dau va ngay ket thuc',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);

    final invitation = await context.read<ContractProvider>().createInvitation({
      'roomId': _selectedRoomId,
      'startDate': _startDate!.toIso8601String().split('T')[0],
      'endDate': _endDate!.toIso8601String().split('T')[0],
      'actualRentPrice': double.tryParse(_priceCtrl.text) ?? 0,
      'elecPriceOverride': double.tryParse(_elecCtrl.text),
      'waterPriceOverride': double.tryParse(_waterCtrl.text),
      'penaltyTerms': _penaltyCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (invitation == null) {
      _showMessage(
        context.read<ContractProvider>().error ?? 'Tao ma thue that bai',
        isError: true,
      );
      return;
    }

    await _showInvitationSheet(invitation);
    if (mounted) {
      context.pop();
    }
  }

  Future<void> _showInvitationSheet(ContractInvitationModel invitation) async {
    final room = _selectedRoom;
    final effectiveElec = invitation.elecPriceOverride ?? room?.elecPrice ?? 0;
    final effectiveWater =
        invitation.waterPriceOverride ?? room?.waterPrice ?? 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
        final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
        final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ma thue da san sang',
                    style: AppTextStyles.h3.copyWith(color: fg),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gui ma nay cho nguoi thue. Ma co hieu luc den ${AppDateUtils.formatDateTime(invitation.expiresAt)}.',
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: SelectableText(
                      invitation.inviteCode,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PreviewRow(
                          label: 'Phong',
                          value:
                              '${invitation.roomCode} - ${invitation.areaName}',
                        ),
                        _PreviewRow(
                          label: 'Ngay thue',
                          value:
                              '${AppDateUtils.formatDate(invitation.startDate)} - ${AppDateUtils.formatDate(invitation.endDate)}',
                        ),
                        _PreviewRow(
                          label: 'Gia phong',
                          value: CurrencyUtils.format(
                            invitation.actualRentPrice,
                          ),
                        ),
                        _PreviewRow(
                          label: 'Gia dien',
                          value: CurrencyUtils.format(effectiveElec),
                        ),
                        _PreviewRow(
                          label: 'Gia nuoc',
                          value: CurrencyUtils.format(effectiveWater),
                        ),
                        if ((invitation.penaltyTerms ?? '').trim().isNotEmpty)
                          _PreviewRow(
                            label: 'Dieu khoan',
                            value: invitation.penaltyTerms!,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Đóng',
                          onPressed: () => Navigator.of(context).pop(),
                          variant: AppButtonVariant.outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Sao chép mã',
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: invitation.inviteCode),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Đã sao chép mã thuê'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
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
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final rooms = context
        .watch<RoomProvider>()
        .rooms
        .where((room) => room.status == 'AVAILABLE')
        .toList();
    final selectedRoom = _selectedRoom;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Tao hop dong moi',
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
              Text(
                '1. Chon phong trong',
                style: AppTextStyles.h3.copyWith(color: fg),
              ),
              const SizedBox(height: 8),
              Text(
                'Chon phong dang AVAILABLE truoc khi nhap dieu khoan hop dong.',
                style: AppTextStyles.bodySmall.copyWith(color: subtext),
              ),
              const SizedBox(height: 16),
              _DropdownField<int>(
                label: 'Phong *',
                hint: 'Chon phong trong',
                value: _selectedRoomId,
                items: rooms
                    .map(
                      (room) => DropdownMenuItem(
                        value: room.roomId,
                        child: Text('${room.roomCode} - ${room.areaName}'),
                      ),
                    )
                    .toList(),
                onChanged: _handleRoomChanged,
                border: border,
                fg: fg,
                subtext: subtext,
              ),
              const SizedBox(height: 8),
              if (rooms.isEmpty)
                Text(
                  'Chưa có phòng trống. Tạo phòng mới hoặc đổi trạng thái phòng.',
                  style: AppTextStyles.bodySmall.copyWith(color: subtext),
                ),
              TextButton.icon(
                onPressed: _openCreateRoomFlow,
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('Thêm phòng mới'),
              ),
              if (selectedRoom != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedRoom.roomCode} - ${selectedRoom.areaName}',
                        style: AppTextStyles.body.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _PreviewRow(
                        label: 'Gia phong mac dinh',
                        value: CurrencyUtils.format(selectedRoom.basePrice),
                      ),
                      _PreviewRow(
                        label: 'Gia dien mac dinh',
                        value: CurrencyUtils.format(selectedRoom.elecPrice),
                      ),
                      _PreviewRow(
                        label: 'Gia nuoc mac dinh',
                        value: CurrencyUtils.format(selectedRoom.waterPrice),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                '2. Cau hinh hop dong',
                style: AppTextStyles.h3.copyWith(color: fg),
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
                      border: border,
                      fg: fg,
                      subtext: subtext,
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
                      border: border,
                      fg: fg,
                      subtext: subtext,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Giá phòng *',
                hint: '3000000',
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money_rounded,
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Vui lòng nhập giá phòng hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Giá điện',
                      hint: '3500',
                      controller: _elecCtrl,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Vui lòng nhập giá điện';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Giá điện không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Giá nước',
                      hint: '15000',
                      controller: _waterCtrl,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Vui lòng nhập giá nước';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Giá nước không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Điều khoản phạt',
                hint: 'Nếu trả phòng sớm, thông báo trước 30 ngày...',
                controller: _penaltyCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Tao ma thue',
                onPressed: _submit,
                loading: _loading,
              ),
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
  final Color border;
  final Color fg;
  final Color subtext;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.border,
    required this.fg,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

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
  final Color border;
  final Color fg;
  final Color subtext;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.border,
    required this.fg,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;

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

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: subtext),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
