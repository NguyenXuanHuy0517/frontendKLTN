import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../data/models/contract_model.dart';
import '../../../data/models/service_model.dart';
import '../../../data/services/tenant_subscription_service.dart';
import '../../../providers/auth_provider.dart';

class TenantServiceScreen extends StatefulWidget {
  const TenantServiceScreen({super.key});

  @override
  State<TenantServiceScreen> createState() => _TenantServiceScreenState();
}

class _TenantServiceScreenState extends State<TenantServiceScreen> {
  final _subscriptionService = TenantSubscriptionService();

  bool _loading = true;
  String? _error;
  int? _userId;
  ContractModel? _contract;
  List<ServiceModel> _contractServices = [];
  List<ServiceModel> _availableServices = [];
  final Set<int> _busyServiceIds = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<ServiceModel> get _filteredAvailableServices {
    final assignedIds = _contractServices.map((item) => item.serviceId).toSet();
    return _availableServices
        .where((service) => !assignedIds.contains(service.serviceId))
        .toList()
      ..sort(
        (a, b) =>
            a.serviceName.toLowerCase().compareTo(b.serviceName.toLowerCase()),
      );
  }

  Future<void> _load() async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
      _userId = userId;
    });

    if (userId == null) {
      setState(() {
        _loading = false;
        _error = 'Không xác định được tài khoản hiện tại.';
      });
      return;
    }

    try {
      final contract = await _subscriptionService.getCurrentContract(userId);
      if (!mounted) return;

      if (contract == null) {
        setState(() {
          _contract = null;
          _contractServices = [];
          _availableServices = [];
          _loading = false;
        });
        return;
      }

      final results = await Future.wait([
        _subscriptionService.getContractServices(contract.contractId),
        _subscriptionService.getAvailableServices(contract.contractId),
      ]);

      if (!mounted) return;
      setState(() {
        _contract = contract;
        _contractServices = results[0];
        _availableServices = results[1];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không tải được danh sách dịch vụ hiện tại.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<int?> _openQuantityDialog({
    required String title,
    required String submitLabel,
    int initialQuantity = 1,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => _QuantityDialog(
        title: title,
        submitLabel: submitLabel,
        initialQuantity: initialQuantity,
      ),
    );
  }

  Future<void> _rentService(ServiceModel service) async {
    final contract = _contract;
    final userId = _userId;
    if (contract == null || userId == null) return;

    final quantity = await _openQuantityDialog(
      title: 'Thuê dịch vụ ${service.serviceName}',
      submitLabel: 'Thuê',
    );
    if (quantity == null || !mounted) return;

    setState(() => _busyServiceIds.add(service.serviceId));
    try {
      await _subscriptionService.addService(
        userId: userId,
        contractId: contract.contractId,
        serviceId: service.serviceId,
        quantity: quantity,
      );
      await _load();
      _showSnackBar('Đăng ký dịch vụ thành công.');
    } catch (_) {
      _showSnackBar('Không thể đăng ký dịch vụ này.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyServiceIds.remove(service.serviceId));
      }
    }
  }

  Future<void> _updateQuantity(ServiceModel service) async {
    final contract = _contract;
    final userId = _userId;
    if (contract == null || userId == null) return;

    final quantity = await _openQuantityDialog(
      title: 'Cập nhật số lượng ${service.serviceName}',
      submitLabel: 'Lưu',
      initialQuantity: service.quantity,
    );
    if (quantity == null || !mounted) return;

    setState(() => _busyServiceIds.add(service.serviceId));
    try {
      await _subscriptionService.updateQuantity(
        userId: userId,
        contractId: contract.contractId,
        serviceId: service.serviceId,
        quantity: quantity,
      );
      await _load();
      _showSnackBar('Đã cập nhật số lượng dịch vụ.');
    } catch (_) {
      _showSnackBar('Không cập nhật được số lượng dịch vụ.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyServiceIds.remove(service.serviceId));
      }
    }
  }

  Future<void> _removeService(ServiceModel service) async {
    final contract = _contract;
    final userId = _userId;
    if (contract == null || userId == null) return;

    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Ngừng thuê dịch vụ',
      message:
          'Bạn có chắc muốn ngừng thuê "${service.serviceName}" khỏi hợp đồng hiện tại?',
      confirmLabel: 'Ngừng thuê',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyServiceIds.add(service.serviceId));
    try {
      await _subscriptionService.removeService(
        userId: userId,
        contractId: contract.contractId,
        serviceId: service.serviceId,
      );
      await _load();
      _showSnackBar('Đã ngừng thuê dịch vụ.');
    } catch (_) {
      _showSnackBar('Không ngừng thuê được dịch vụ này.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyServiceIds.remove(service.serviceId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final contract = _contract;
    final availableServices = _filteredAvailableServices;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          'Dịch vụ đang thuê',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
      ),
      body: _loading
          ? const AppLoading()
          : _error != null
          ? RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  AppEmpty(
                    message: _error!,
                    icon: Icons.miscellaneous_services_outlined,
                    actionLabel: 'Thử lại',
                    onAction: _load,
                  ),
                ],
              ),
            )
          : contract == null
          ? RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  AppEmpty(
                    message:
                        'Chưa có hợp đồng đang hiệu lực để quản lý dịch vụ.',
                    icon: Icons.miscellaneous_services_outlined,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  AppCard(
                    featured: _contractServices.isNotEmpty,
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
                                    'Phòng ${contract.roomCode}',
                                    style: AppTextStyles.h3.copyWith(color: fg),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    contract.areaName,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: subtext,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Hóa đơn hàng tháng',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _TenantStatPill(
                              icon: Icons.miscellaneous_services_outlined,
                              color: AppColors.accent,
                              label: '${_contractServices.length} đang sử dụng',
                            ),
                            _TenantStatPill(
                              icon: Icons.add_box_outlined,
                              color: AppColors.info,
                              label:
                                  '${availableServices.length} có thể đăng ký',
                            ),
                            const _TenantStatPill(
                              icon: Icons.home_work_outlined,
                              color: AppColors.success,
                              label: 'Theo khu trọ đang thuê',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Dịch vụ đang sử dụng',
                    style: AppTextStyles.h3.copyWith(color: fg),
                  ),
                  const SizedBox(height: 12),
                  if (_contractServices.isEmpty)
                    AppEmpty(
                      message: availableServices.isEmpty
                          ? 'Khu trọ hiện tại chưa có dịch vụ nào để đăng ký.'
                          : 'Bạn chưa đăng ký dịch vụ nào. Có thể chọn thêm ở phần bên dưới.',
                      icon: Icons.layers_clear_outlined,
                    )
                  else
                    ..._contractServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TenantServiceCard(
                          service: service,
                          busy: _busyServiceIds.contains(service.serviceId),
                          primaryLabel: 'Ngừng thuê',
                          primaryColor: AppColors.error,
                          onPrimary: () => _removeService(service),
                          secondaryLabel: 'Sửa số lượng',
                          onSecondary: () => _updateQuantity(service),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Có thể đăng ký thêm',
                    style: AppTextStyles.h3.copyWith(color: fg),
                  ),
                  const SizedBox(height: 12),
                  if (availableServices.isEmpty)
                    AppCard(
                      child: Text(
                        'Hiện không còn dịch vụ nào khác trong khu trọ để đăng ký thêm.',
                        style: AppTextStyles.bodySmall.copyWith(color: subtext),
                      ),
                    )
                  else
                    ...availableServices.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TenantServiceCard(
                          service: service,
                          busy: _busyServiceIds.contains(service.serviceId),
                          primaryLabel: 'Thuê dịch vụ',
                          primaryColor: AppColors.accent,
                          onPrimary: () => _rentService(service),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Các dịch vụ được áp dụng theo hợp đồng đang thuê và sẽ được tính vào hóa đơn theo cấu hình của chủ trọ.',
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 3),
    );
  }
}

class _QuantityDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final int initialQuantity;

  const _QuantityDialog({
    required this.title,
    required this.submitLabel,
    required this.initialQuantity,
  });

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final TextEditingController _quantityCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _quantityCtrl = TextEditingController(text: '${widget.initialQuantity}');
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final quantity = int.tryParse(_quantityCtrl.text.trim());
    if (quantity == null || quantity <= 0) return;
    Navigator.of(context).pop(quantity);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _quantityCtrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số lượng',
            hintText: '1',
          ),
          onFieldSubmitted: (_) => _submit(),
          validator: (value) {
            final parsed = int.tryParse((value ?? '').trim());
            if (parsed == null || parsed <= 0) {
              return 'Nhập số lượng hợp lệ';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _TenantStatPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _TenantStatPill({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _TenantServiceCard extends StatelessWidget {
  final ServiceModel service;
  final bool busy;
  final String primaryLabel;
  final Color primaryColor;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _TenantServiceCard({
    required this.service,
    required this.busy,
    required this.primaryLabel,
    required this.primaryColor,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
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
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.miscellaneous_services_outlined,
                  color: AppColors.accent,
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
                    if ((service.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        service.description!,
                        style: AppTextStyles.bodySmall.copyWith(color: subtext),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Số lượng: ${service.quantity}',
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                    ),
                    if (service.priceSnapshot != null &&
                        service.priceSnapshot != service.price) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Giá tại hợp đồng: ${CurrencyUtils.format(service.priceSnapshot!)}/${service.displayUnit}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (secondaryLabel != null && onSecondary != null)
                TextButton(
                  onPressed: busy ? null : onSecondary,
                  child: Text(secondaryLabel!),
                ),
              const Spacer(),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(primaryLabel),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
