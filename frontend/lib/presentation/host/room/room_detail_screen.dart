import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/contract_model.dart';
import '../../../data/models/room_model.dart';
import '../../../data/models/service_model.dart';
import '../../../data/services/contract_service.dart';
import '../../../data/services/service_management.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';

class RoomDetailScreen extends StatefulWidget {
  final int roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _contractService = ContractService();
  final _serviceManagement = ServiceManagement();

  bool _serviceLoading = false;
  String? _serviceError;
  ContractModel? _currentContract;
  List<ServiceModel> _areaServices = [];
  final Set<int> _busyServiceIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRoom());
  }

  Future<void> _loadRoom() async {
    await context.read<RoomProvider>().fetchRoomDetail(widget.roomId);
    if (!mounted) return;
    final room = context.read<RoomProvider>().selected;
    if (room != null) {
      await _loadServiceContext(room);
    }
  }

  Future<void> _loadServiceContext(RoomModel room) async {
    if (mounted) {
      setState(() {
        _serviceLoading = true;
        _serviceError = null;
      });
    }

    try {
      final services = await _serviceManagement.getServices(room.areaId);
      ContractModel? contract;
      if (room.currentContractId != null) {
        contract = await _contractService.getContractDetail(
          room.currentContractId!,
        );
      }

      if (!mounted) return;
      setState(() {
        _areaServices = services;
        _currentContract = contract;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serviceError = 'Không tải được dữ liệu dịch vụ của phòng.';
      });
    } finally {
      if (mounted) {
        setState(() => _serviceLoading = false);
      }
    }
  }

  List<ServiceModel> get _assignedServices {
    final contractServices = _currentContract?.contractServices ?? [];
    return [...contractServices]
      ..sort(
        (a, b) =>
            a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase()),
      );
  }

  List<ServiceModel> get _availableServicesToAssign {
    final assignedIds = _assignedServices.map((item) => item.serviceId).toSet();
    return _areaServices
        .where(
          (service) =>
              service.active && !assignedIds.contains(service.serviceId),
        )
        .toList()
      ..sort(
        (a, b) =>
            a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase()),
      );
  }

  Future<void> _changeStatus(String newStatus) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Đổi trạng thái phòng',
      message: 'Xác nhận chuyển phòng sang trạng thái mới?',
    );
    if (!confirm || !mounted) return;

    final hostId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    final ok = await context.read<RoomProvider>().updateStatus(
      widget.roomId,
      newStatus,
      null,
      hostId!,
    );

    if (!mounted) return;
    _showSnackBar(
      ok ? 'Cập nhật thành công' : 'Cập nhật thất bại',
      isError: !ok,
    );
    if (ok) {
      await _loadRoom();
    }
  }

  Future<void> _addServiceToRoom(RoomModel room) async {
    if (room.currentContractId == null) return;
    final availableServices = _availableServicesToAssign;
    if (availableServices.isEmpty) {
      _showSnackBar(
        'Không còn dịch vụ hoạt động nào để thêm cho phòng này.',
        isError: true,
      );
      return;
    }

    int? selectedServiceId = availableServices.first.serviceId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Thêm dịch vụ cho phòng'),
          content: DropdownButtonFormField<int>(
            initialValue: selectedServiceId,
            decoration: const InputDecoration(labelText: 'Chọn dịch vụ'),
            items: availableServices
                .map(
                  (service) => DropdownMenuItem<int>(
                    value: service.serviceId,
                    child: Text(
                      '${service.serviceName} • ${CurrencyUtils.format(service.price)}/${service.unitName}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) => selectedServiceId = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || selectedServiceId == null || !mounted) return;

    setState(() => _busyServiceIds.add(selectedServiceId!));
    try {
      await _contractService.addService(
        room.currentContractId!,
        selectedServiceId!,
      );
      await _loadServiceContext(room);
      _showSnackBar('Đã thêm dịch vụ cho phòng.');
    } catch (_) {
      _showSnackBar('Không thêm được dịch vụ cho phòng.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyServiceIds.remove(selectedServiceId));
      }
    }
  }

  Future<void> _removeServiceFromRoom(
    RoomModel room,
    ServiceModel service,
  ) async {
    if (room.currentContractId == null) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Xóa dịch vụ khỏi phòng',
      message:
          'Dịch vụ "${service.serviceName}" sẽ bị gỡ khỏi hợp đồng hiện tại của tenant. Tiếp tục?',
      confirmLabel: 'Xóa',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyServiceIds.add(service.serviceId));
    try {
      await _contractService.removeService(
        room.currentContractId!,
        service.serviceId,
      );
      await _loadServiceContext(room);
      _showSnackBar('Đã xóa dịch vụ khỏi phòng.');
    } catch (_) {
      _showSnackBar('Không xóa được dịch vụ khỏi phòng.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyServiceIds.remove(service.serviceId));
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
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
    final room = context.watch<RoomProvider>().selected;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          room != null ? 'Phòng ${room.roomCode}' : 'Chi tiết phòng',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          if (room != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.accent),
              onPressed: () => context.push('/host/rooms/${widget.roomId}/edit'),
            ),
        ],
      ),
      body: room == null
          ? const AppLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _statusColor(room.status).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _statusColor(room.status).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _statusColor(room.status)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.meeting_room_outlined,
                            color: _statusColor(room.status),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phòng ${room.roomCode}',
                                style: AppTextStyles.h3.copyWith(color: fg),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                room.areaName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: subtext,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StatusBadge(status: room.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Giá thuê',
                          value: CurrencyUtils.format(room.basePrice),
                          valueColor: AppColors.accent,
                          isDark: isDark,
                        ),
                        Divider(color: border, height: 24),
                        _InfoRow(
                          label: 'Giá điện',
                          value: '${CurrencyUtils.format(room.elecPrice)}/kWh',
                          isDark: isDark,
                        ),
                        Divider(color: border, height: 24),
                        _InfoRow(
                          label: 'Giá nước',
                          value: '${CurrencyUtils.format(room.waterPrice)}/m³',
                          isDark: isDark,
                        ),
                        if (room.areaSize != null) ...[
                          Divider(color: border, height: 24),
                          _InfoRow(
                            label: 'Diện tích',
                            value: '${room.areaSize} m²',
                            isDark: isDark,
                          ),
                        ],
                        if (room.floor != null) ...[
                          Divider(color: border, height: 24),
                          _InfoRow(
                            label: 'Tầng',
                            value: '${room.floor}',
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (room.currentTenantName != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      featured: true,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Người đang thuê',
                                  style: AppTextStyles.caption.copyWith(
                                    color: subtext,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  room.currentTenantName!,
                                  style: AppTextStyles.body.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (room.currentContractId != null)
                            TextButton(
                              onPressed: () => context.push(
                                '/host/contracts/${room.currentContractId}',
                              ),
                              child: const Text('Xem HĐ'),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (room.currentContractId != null) ...[
                    const SizedBox(height: 16),
                    _RoomServiceSection(
                      room: room,
                      isDark: isDark,
                      loading: _serviceLoading,
                      error: _serviceError,
                      assignedServices: _assignedServices,
                      availableServices: _availableServicesToAssign,
                      busyServiceIds: _busyServiceIds,
                      onAddService: () => _addServiceToRoom(room),
                      onRemoveService: (service) =>
                          _removeServiceFromRoom(room, service),
                      onManageCatalog: () => context.push(
                        Uri(
                          path: '/host/areas/${room.areaId}/services',
                          queryParameters: {'areaName': room.areaName},
                        ).toString(),
                      ),
                    ),
                  ],
                  if ((room.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mô tả',
                            style: AppTextStyles.body.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            room.description!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: subtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (room.status != 'RENTED') ...[
                    Text(
                      'Thay đổi trạng thái',
                      style: AppTextStyles.h3.copyWith(color: fg),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (room.status != 'AVAILABLE')
                          _StatusBtn(
                            label: 'Còn trống',
                            color: AppColors.roomAvailable,
                            onTap: () => _changeStatus('AVAILABLE'),
                          ),
                        if (room.status != 'MAINTENANCE')
                          _StatusBtn(
                            label: 'Bảo trì',
                            color: AppColors.roomMaintenance,
                            onTap: () => _changeStatus('MAINTENANCE'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppColors.roomAvailable;
      case 'RENTED':
        return AppColors.roomRented;
      case 'DEPOSITED':
        return AppColors.roomDeposited;
      case 'MAINTENANCE':
        return AppColors.roomMaintenance;
      default:
        return AppColors.accent;
    }
  }
}

class _RoomServiceSection extends StatelessWidget {
  final RoomModel room;
  final bool isDark;
  final bool loading;
  final String? error;
  final List<ServiceModel> assignedServices;
  final List<ServiceModel> availableServices;
  final Set<int> busyServiceIds;
  final VoidCallback onAddService;
  final VoidCallback onManageCatalog;
  final void Function(ServiceModel service) onRemoveService;

  const _RoomServiceSection({
    required this.room,
    required this.isDark,
    required this.loading,
    required this.error,
    required this.assignedServices,
    required this.availableServices,
    required this.busyServiceIds,
    required this.onAddService,
    required this.onManageCatalog,
    required this.onRemoveService,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      featured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dịch vụ phòng của tenant',
                      style: AppTextStyles.h3.copyWith(color: fg),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Danh sách dịch vụ đang áp dụng cho tenant trong phòng ${room.roomCode}.',
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: 'Thêm',
                fullWidth: false,
                height: 40,
                icon: Icons.add_rounded,
                variant: AppButtonVariant.outlined,
                onPressed: availableServices.isEmpty ? null : onAddService,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onManageCatalog,
              icon: const Icon(Icons.miscellaneous_services_outlined, size: 18),
              label: const Text('Quản lý danh mục dịch vụ'),
            ),
          ),
          if (loading) ...[
            const SizedBox(height: 8),
            const AppLoading(),
          ] else if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
          ] else if (assignedServices.isEmpty) ...[
            const SizedBox(height: 8),
            AppEmpty(
              message: availableServices.isEmpty
                  ? 'Chưa có dịch vụ nào được gắn và khu trọ cũng chưa có dịch vụ khả dụng.'
                  : 'Phòng hiện chưa có dịch vụ nào. Bạn có thể thêm ngay từ đây.',
              icon: Icons.layers_clear_outlined,
              actionLabel: availableServices.isEmpty ? null : 'Thêm dịch vụ',
              onAction: availableServices.isEmpty ? null : onAddService,
            ),
          ] else ...[
            const SizedBox(height: 8),
            ...assignedServices.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.miscellaneous_services_outlined,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.serviceName,
                              style: AppTextStyles.body.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${CurrencyUtils.format(service.displayPrice)}/${service.displayUnit}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Số lượng: ${service.quantity}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: subtext,
                              ),
                            ),
                            if (service.currentServicePrice != null &&
                                service.currentServicePrice !=
                                    service.displayPrice) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Giá dịch vụ hiện tại: ${CurrencyUtils.format(service.currentServicePrice!)}/${service.unitName}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: busyServiceIds.contains(service.serviceId)
                            ? null
                            : () => onRemoveService(service),
                        icon: busyServiceIds.contains(service.serviceId)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Danh sách này đang đọc trực tiếp từ contractServices của backend, nên thao tác thêm/xóa service sẽ bám đúng hợp đồng hiện tại.',
              style: AppTextStyles.bodySmall.copyWith(color: subtext),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: subtext)),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: valueColor ?? fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
