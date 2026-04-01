// Màn hình quản lý dịch vụ theo từng khu trọ của host.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../data/models/area_model.dart';
import '../../../data/models/service_model.dart';
import '../../../data/services/area_service.dart';
import '../../../data/services/service_management.dart';
import '../../../providers/auth_provider.dart';

class HostServiceManagementScreen extends StatefulWidget {
  final int? areaId;
  final String? areaName;

  const HostServiceManagementScreen({super.key, this.areaId, this.areaName});

  @override
  State<HostServiceManagementScreen> createState() =>
      _HostServiceManagementScreenState();
}

class _HostServiceManagementScreenState
    extends State<HostServiceManagementScreen> {
  final _serviceManagement = ServiceManagement();
  final _areaService = AreaService();

  bool _loadingAreas = true;
  bool _loadingServices = false;
  bool _saving = false;
  String? _areaError;
  String? _serviceError;
  List<AreaModel> _areas = [];
  AreaModel? _selectedArea;
  List<ServiceModel> _services = [];

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    final hostId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    setState(() {
      _loadingAreas = true;
      _areaError = null;
    });

    if (hostId == null) {
      setState(() {
        _loadingAreas = false;
        _areaError = 'Không xác định được tài khoản chủ trọ hiện tại.';
      });
      return;
    }

    try {
      final areas = await _areaService.getAreas(hostId);
      areas.sort(
        (a, b) => a.areaName.toLowerCase().compareTo(b.areaName.toLowerCase()),
      );

      AreaModel? selectedArea = _selectedArea;
      if (selectedArea != null) {
        selectedArea = areas.cast<AreaModel?>().firstWhere(
          (item) => item?.areaId == selectedArea?.areaId,
          orElse: () => null,
        );
      } else if (widget.areaId != null) {
        selectedArea = areas.cast<AreaModel?>().firstWhere(
          (item) => item?.areaId == widget.areaId,
          orElse: () => null,
        );
      }

      if (!mounted) return;
      setState(() {
        _areas = areas;
        _selectedArea = selectedArea;
      });

      if (selectedArea != null) {
        await _loadServices(selectedArea.areaId);
      } else if (mounted) {
        setState(() {
          _services = [];
          _serviceError = null;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _areaError = 'Không tải được danh sách khu trọ để quản lý dịch vụ.';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingAreas = false);
      }
    }
  }

  Future<void> _loadServices(int areaId) async {
    if (mounted) {
      setState(() {
        _loadingServices = true;
        _serviceError = null;
      });
    }

    try {
      final services = await _serviceManagement.getServices(areaId);
      services.sort(
        (a, b) =>
            a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase()),
      );

      if (!mounted) return;
      setState(() => _services = services);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _serviceError = 'Không tải được danh mục dịch vụ của khu trọ này.';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingServices = false);
      }
    }
  }

  Future<void> _selectArea(AreaModel area) async {
    if (!mounted) return;
    setState(() {
      _selectedArea = area;
      _services = [];
    });
    await _loadServices(area.areaId);
  }

  Future<void> _openServiceForm({ServiceModel? service}) async {
    final area = _selectedArea;
    if (area == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: service?.serviceName ?? '',
    );
    final priceController = TextEditingController(
      text: service == null ? '' : service.price.toStringAsFixed(0),
    );
    final unitController = TextEditingController(
      text: service?.unitName ?? 'Tháng',
    );
    final descriptionController = TextEditingController(
      text: service?.description ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            service == null ? 'Thêm dịch vụ' : 'Sửa dịch vụ',
            style: AppTextStyles.h3.copyWith(color: fg),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên dịch vụ',
                      hintText: 'Ví dụ: Giữ xe',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nhập tên dịch vụ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá',
                      hintText: 'Ví dụ: 100000',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nhập giá dịch vụ';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Giá không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Đơn vị',
                      hintText: 'Ví dụ: Tháng, Người, Xe',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nhập đơn vị tính';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      hintText: 'Ghi chú thêm nếu cần',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(dialogContext, true);
              },
              child: Text(service == null ? 'Tạo' : 'Lưu'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    final payload = <String, dynamic>{
      'serviceName': nameController.text.trim(),
      'price': double.tryParse(priceController.text.trim()) ?? 0,
      'unitName': unitController.text.trim(),
      'description': descriptionController.text.trim(),
    };

    nameController.dispose();
    priceController.dispose();
    unitController.dispose();
    descriptionController.dispose();

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      if (service == null) {
        await _serviceManagement.createService(area.areaId, payload);
      } else {
        await _serviceManagement.updateService(service.serviceId, payload);
      }
      await _loadServices(area.areaId);
      _showSnackBar(
        service == null
            ? 'Đã thêm dịch vụ mới cho khu trọ.'
            : 'Đã cập nhật dịch vụ.',
      );
    } catch (_) {
      _showSnackBar(
        service == null
            ? 'Không tạo được dịch vụ.'
            : 'Không cập nhật được dịch vụ.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteService(ServiceModel service) async {
    final area = _selectedArea;
    if (area == null) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Ngưng sử dụng dịch vụ',
      message:
          'Dịch vụ "${service.serviceName}" sẽ được chuyển sang trạng thái ngưng sử dụng. Tiếp tục?',
      confirmLabel: 'Ngưng dùng',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    try {
      await _serviceManagement.deleteService(service.serviceId);
      await _loadServices(area.areaId);
      _showSnackBar('Đã cập nhật trạng thái dịch vụ.');
    } catch (_) {
      _showSnackBar('Không cập nhật được dịch vụ.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _goBack() async {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/host/areas');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final selectedArea = _selectedArea;
    final activeCount = _services.where((service) => service.active).length;
    final inactiveCount = _services.length - activeCount;
    final usageCount = _services.fold<int>(
      0,
      (sum, service) => sum + service.usageCount,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        automaticallyImplyLeading: widget.areaId != null,
        leading: widget.areaId != null
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: fg,
                  size: 20,
                ),
                onPressed: _goBack,
              )
            : null,
        title: Text(
          selectedArea == null
              ? 'Dịch vụ khu trọ'
              : 'Dịch vụ ${selectedArea.areaName}',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          if (selectedArea != null)
            IconButton(
              onPressed: _saving ? null : () => _openServiceForm(),
              icon: const Icon(Icons.add_rounded, color: AppColors.accent),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loadingAreas
            ? const AppLoading()
            : _areaError != null
            ? RefreshIndicator(
                color: AppColors.accent,
                onRefresh: _loadAreas,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    AppEmpty(
                      message: _areaError!,
                      icon: Icons.location_city_outlined,
                      actionLabel: 'Thử lại',
                      onAction: _loadAreas,
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: AppColors.accent,
                onRefresh: _loadAreas,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    selectedArea == null ? 32 : 120,
                  ),
                  children: [
                    if (_areas.isEmpty)
                      AppEmpty(
                        message: 'Bạn chưa có khu trọ nào để quản lý dịch vụ.',
                        icon: Icons.location_city_outlined,
                        actionLabel: 'Thêm khu trọ',
                        onAction: () => context.push('/host/areas/new'),
                      )
                    else ...[
                      Text(
                        'Chọn khu trọ',
                        style: AppTextStyles.h3.copyWith(color: fg),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mỗi khu trọ có danh mục dịch vụ riêng. Chọn một khu để xem và chỉnh sửa.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkSubtext
                              : AppColors.lightSubtext,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 156,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _areas.length,
                          separatorBuilder: (context, separatorIndex) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, index) {
                            final area = _areas[index];
                            return _AreaSelectorCard(
                              area: area,
                              selected: area.areaId == selectedArea?.areaId,
                              onTap: () => _selectArea(area),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (selectedArea == null)
                        const AppEmpty(
                          message:
                              'Hãy chọn một khu trọ ở phía trên để hiển thị danh sách dịch vụ.',
                          icon: Icons.miscellaneous_services_outlined,
                        )
                      else if (_loadingServices)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: AppLoading(),
                        )
                      else if (_serviceError != null)
                        AppEmpty(
                          message: _serviceError!,
                          icon: Icons.miscellaneous_services_outlined,
                          actionLabel: 'Tải lại',
                          onAction: () => _loadServices(selectedArea.areaId),
                        )
                      else ...[
                        AppCard(
                          featured: activeCount > 0,
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _ServiceSummaryChip(
                                label: '$activeCount dịch vụ đang dùng',
                                icon: Icons.check_circle_outline,
                                color: AppColors.success,
                              ),
                              _ServiceSummaryChip(
                                label: '$inactiveCount dịch vụ ngưng dùng',
                                icon: Icons.pause_circle_outline,
                                color: AppColors.warning,
                              ),
                              _ServiceSummaryChip(
                                label: '$usageCount lượt gắn hợp đồng',
                                icon: Icons.people_outline_rounded,
                                color: AppColors.accent,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_services.isEmpty)
                          AppEmpty(
                            message:
                                'Khu trọ này chưa có dịch vụ nào. Bạn có thể tạo ngay từ màn này.',
                            icon: Icons.miscellaneous_services_outlined,
                            actionLabel: 'Thêm dịch vụ',
                            onAction: () => _openServiceForm(),
                          )
                        else
                          ..._services.map(
                            (service) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ServiceCard(
                                service: service,
                                onEdit: _saving || !service.active
                                    ? null
                                    : () => _openServiceForm(service: service),
                                onDelete: _saving || !service.active
                                    ? null
                                    : () => _deleteService(service),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: selectedArea == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : () => _openServiceForm(),
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Thêm dịch vụ',
                style: TextStyle(color: Colors.white),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const HostBottomNav(currentIndex: 2),
    );
  }
}

class _AreaSelectorCard extends StatelessWidget {
  final AreaModel area;
  final bool selected;
  final VoidCallback onTap;

  const _AreaSelectorCard({
    required this.area,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = selected
        ? AppColors.accent
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 244,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.08)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_city_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              area.areaName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              area.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: subtext),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AreaStatText(
                  label: '${area.totalRooms} phòng',
                  color: AppColors.accent,
                ),
                _AreaStatText(
                  label: '${area.rentedRooms} đang thuê',
                  color: AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaStatText extends StatelessWidget {
  final String label;
  final Color color;

  const _AreaStatText({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ServiceSummaryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ServiceSummaryChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ServiceCard({required this.service, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final statusColor = service.active ? AppColors.success : AppColors.warning;

    return AppCard(
      featured: service.active,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  service.active
                      ? Icons.miscellaneous_services_outlined
                      : Icons.pause_circle_outline,
                  color: statusColor,
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
                      '${CurrencyUtils.format(service.price)}/${service.unitName}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if ((service.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        service.description!,
                        style: AppTextStyles.bodySmall.copyWith(color: subtext),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Sửa dịch vụ'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Ngưng sử dụng'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: border, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  service.active ? 'Đang hoạt động' : 'Ngưng sử dụng',
                  style: AppTextStyles.caption.copyWith(color: statusColor),
                ),
              ),
              const Spacer(),
              Text(
                'Đã gắn ${service.usageCount} hợp đồng',
                style: AppTextStyles.caption.copyWith(color: subtext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
