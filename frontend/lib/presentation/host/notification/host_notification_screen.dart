import 'dart:async';

import 'package:flutter/material.dart';

// Màn hình hộp thư và trung tâm gửi thông báo dành cho host.
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/error_retry_widget.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/list_search_field.dart';
import '../../../core/widgets/paged_load_more.dart';
import '../../../data/models/contract_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/tenant_model.dart';
import '../../../data/services/contract_service.dart';
import '../../../data/services/host_notification_service.dart';
import '../../../data/services/invoice_service.dart';
import '../../../data/services/tenant_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/host_notification_list_provider.dart';
import '../../../providers/notification_badge_provider.dart';

enum HostNotificationScreenMode { inbox, sendCenter }

class HostNotificationScreen extends StatefulWidget {
  const HostNotificationScreen({
    super.key,
    this.mode = HostNotificationScreenMode.inbox,
  });

  final HostNotificationScreenMode mode;

  @override
  State<HostNotificationScreen> createState() => _HostNotificationScreenState();
}

class _HostNotificationScreenState extends State<HostNotificationScreen>
    with SingleTickerProviderStateMixin {
  final _notificationService = HostNotificationService();
  final _tenantService = TenantService();
  final _invoiceService = InvoiceService();
  final _contractService = ContractService();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _searchController = TextEditingController();
  final _sendingKeys = <String>{};
  final _sentQuickKeys = <String>{};
  final _readFilters = const [
    _ReadFilterOption(label: 'Tat ca', value: null),
    _ReadFilterOption(label: 'Chua doc', value: false),
    _ReadFilterOption(label: 'Da doc', value: true),
  ];

  late final TabController _tabController;
  Timer? _searchDebounce;

  int? _hostId;
  bool _loading = true;
  bool _sendingManual = false;
  bool _sendingAllInvoices = false;
  bool _sendingAllContracts = false;
  String? _error;

  List<TenantModel> _tenants = [];
  List<InvoiceModel> _overdueInvoices = [];
  List<ContractModel> _expiringContracts = [];

  String _recipientMode = 'ALL';
  int? _selectedTenantId;
  String _selectedType = 'HOST_ANNOUNCEMENT';

  static const _typeOptions = [
    _NotificationTypeOption(
      value: 'HOST_ANNOUNCEMENT',
      label: 'Thông báo chung',
    ),
    _NotificationTypeOption(
      value: 'INVOICE_DUE',
      label: 'Nhắc thanh toán hóa đơn',
    ),
    _NotificationTypeOption(value: 'INVOICE_OVERDUE', label: 'Hóa đơn quá hạn'),
    _NotificationTypeOption(
      value: 'CONTRACT_EXPIRING',
      label: 'Hợp đồng sắp hết hạn',
    ),
    _NotificationTypeOption(
      value: 'ISSUE_UPDATED',
      label: 'Cập nhật khiếu nại',
    ),
  ];

  bool get _isInboxMode => widget.mode == HostNotificationScreenMode.inbox;

  bool get _isSendCenterMode =>
      widget.mode == HostNotificationScreenMode.sendCenter;

  List<String> get _tabLabels => _isSendCenterMode
      ? const ['Gửi thủ công', 'Gửi nhanh']
      : const ['Hộp thư'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  List<TenantModel> get _activeTenants {
    final list = _tenants.where(_isCurrentTenant).toList();
    list.sort(
      (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
    );
    return list;
  }

  List<_QuickInvoiceReminder> get _invoiceReminders {
    return _overdueInvoices
        .map(
          (invoice) => _QuickInvoiceReminder(
            invoice: invoice,
            tenant: _resolveTenant(
              tenantName: invoice.tenantName,
              roomCode: invoice.roomCode,
            ),
          ),
        )
        .toList();
  }

  List<_QuickContractReminder> get _contractReminders {
    return _expiringContracts
        .map(
          (contract) => _QuickContractReminder(
            contract: contract,
            daysLeft: _daysUntil(contract.endDate) ?? 0,
            tenant: _resolveTenant(
              tenantName: contract.tenantName,
              roomCode: contract.roomCode,
            ),
          ),
        )
        .toList();
  }

  void _syncUnreadBadge([int? count]) {
    if (!mounted) return;
    context.read<NotificationBadgeProvider>().setHostUnreadCount(
      count ??
          (_isInboxMode
              ? context.read<HostNotificationListProvider>().unreadCount
              : 0),
    );
  }

  Future<void> _load() async {
    final authProvider = context.read<AuthProvider>();
    final notificationListProvider = context
        .read<HostNotificationListProvider>();
    final hostId = await authProvider.getUserId();
    if (hostId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không xác định được tài khoản chủ trọ hiện tại.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _hostId = hostId;
        _loading = true;
        _error = null;
      });
    }

    try {
      if (_isInboxMode) {
        _searchController.text = notificationListProvider.search;
        await notificationListProvider.bootstrap(userId: hostId);
        _syncUnreadBadge(notificationListProvider.unreadCount);
        return;
      } else {
        final results = await Future.wait<dynamic>([
          _tenantService.getTenants(hostId),
          _invoiceService.getOverdueInvoices(hostId),
          _contractService.getContracts(hostId),
        ]);

        final tenants = results[0] as List<TenantModel>;
        final overdueInvoices = results[1] as List<InvoiceModel>;
        final expiringContracts = _filterExpiringContracts(
          results[2] as List<ContractModel>,
        );

        if (!mounted) return;
        setState(() {
          _tenants = tenants;
          _overdueInvoices = overdueInvoices;
          _expiringContracts = expiringContracts;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải dữ liệu thông báo lúc này. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    try {
      await context.read<HostNotificationListProvider>().loadMore();
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Khong the tai them thong bao.', isError: true);
    }
  }

  bool _isCurrentTenant(TenantModel tenant) {
    final contractStatus = (tenant.contractStatus ?? '').toUpperCase();
    final hasRoom = (tenant.currentRoomCode ?? '').trim().isNotEmpty;
    return tenant.active &&
        (contractStatus.isEmpty || contractStatus == 'ACTIVE' || hasRoom);
  }

  List<ContractModel> _filterExpiringContracts(List<ContractModel> contracts) {
    final filtered = contracts.where((contract) {
      if (contract.status.toUpperCase() != 'ACTIVE') return false;
      final daysLeft = _daysUntil(contract.endDate);
      return daysLeft != null && daysLeft >= 0 && daysLeft <= 30;
    }).toList();

    filtered.sort((a, b) {
      final left = _daysUntil(a.endDate) ?? 9999;
      final right = _daysUntil(b.endDate) ?? 9999;
      return left.compareTo(right);
    });

    return filtered;
  }

  int? _daysUntil(String? date) {
    if (date == null || date.isEmpty) return null;
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return null;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(parsed.year, parsed.month, parsed.day);
    return end.difference(start).inDays;
  }

  TenantModel? _resolveTenant({
    required String tenantName,
    required String roomCode,
  }) {
    final name = _normalize(tenantName);
    final room = _normalize(roomCode);
    final tenants = _activeTenants;

    if (room.isNotEmpty && name.isNotEmpty) {
      final exact = tenants
          .where(
            (tenant) =>
                _normalize(tenant.fullName) == name &&
                _normalize(tenant.currentRoomCode) == room,
          )
          .toList();
      if (exact.length == 1) return exact.first;
    }

    if (room.isNotEmpty) {
      final roomMatches = tenants
          .where((tenant) => _normalize(tenant.currentRoomCode) == room)
          .toList();
      if (roomMatches.length == 1) return roomMatches.first;
    }

    if (name.isNotEmpty) {
      final nameMatches = tenants
          .where((tenant) => _normalize(tenant.fullName) == name)
          .toList();
      if (nameMatches.length == 1) return nameMatches.first;
    }

    return null;
  }

  String _normalize(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _markAllRead() async {
    try {
      await context.read<HostNotificationListProvider>().markAllAsRead();
      _syncUnreadBadge();
    } catch (_) {
      _showSnackBar('Không thể đánh dấu tất cả là đã đọc.', isError: true);
    }
  }

  Future<void> _openNotification(NotificationModel notification) async {
    final router = GoRouter.of(context);
    if (!notification.isRead) {
      try {
        await context.read<HostNotificationListProvider>().markAsRead(
          notification.notificationId,
        );
        _syncUnreadBadge();
      } catch (_) {
        _showSnackBar('Không cập nhật trạng thái đã đọc được.', isError: true);
      }
    }

    final refType = (notification.refType ?? '').toUpperCase();
    final refId = notification.refId;
    if (refId == null) return;

    switch (refType) {
      case 'INVOICE':
        router.push('/host/invoices/$refId');
        return;
      case 'CONTRACT':
        router.push('/host/contracts/$refId');
        return;
      case 'ISSUE':
        router.push('/host/issues/$refId');
        return;
      case 'ROOM':
        router.push('/host/rooms/$refId');
        return;
    }
  }

  Future<void> _sendManualNotification() async {
    final hostId = _hostId;
    if (hostId == null) return;

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _showSnackBar(
        'Nhập đầy đủ tiêu đề và nội dung thông báo.',
        isError: true,
      );
      return;
    }

    final recipients = _recipientMode == 'ALL'
        ? _activeTenants
        : _activeTenants
              .where((tenant) => tenant.userId == _selectedTenantId)
              .toList();

    if (recipients.isEmpty) {
      _showSnackBar(
        _recipientMode == 'ALL'
            ? 'Không có người thuê đang hoạt động để gửi.'
            : 'Hãy chọn một người nhận cụ thể.',
        isError: true,
      );
      return;
    }

    setState(() => _sendingManual = true);
    try {
      for (final tenant in recipients) {
        await _notificationService.sendNotification(
          hostId: hostId,
          tenantId: tenant.userId,
          type: _selectedType,
          title: title,
          body: body,
        );
      }

      if (!mounted) return;
      _titleController.clear();
      _bodyController.clear();
      _showSnackBar(
        _recipientMode == 'ALL'
            ? 'Đã gửi thông báo cho ${recipients.length} người thuê.'
            : 'Đã gửi thông báo cho ${recipients.first.fullName}.',
      );
    } catch (_) {
      _showSnackBar(
        'Gửi thông báo thất bại. Vui lòng thử lại sau.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _sendingManual = false);
      }
    }
  }

  Future<void> _sendInvoiceReminder(
    _QuickInvoiceReminder reminder, {
    bool silent = false,
  }) async {
    final hostId = _hostId;
    final tenant = reminder.tenant;
    if (hostId == null || tenant == null) return;

    final key = reminder.key;
    if (_sendingKeys.contains(key) || _sentQuickKeys.contains(key)) return;

    setState(() => _sendingKeys.add(key));
    try {
      await _notificationService.sendNotification(
        hostId: hostId,
        tenantId: tenant.userId,
        type: 'INVOICE_OVERDUE',
        title: 'Nhắc thanh toán hóa đơn quá hạn',
        body: _buildInvoiceReminderBody(reminder.invoice),
        refType: 'INVOICE',
        refId: reminder.invoice.invoiceId,
      );
      if (!mounted) return;
      setState(() => _sentQuickKeys.add(key));
      if (!silent) {
        _showSnackBar('Đã gửi nhắc hóa đơn cho ${tenant.fullName}.');
      }
    } catch (_) {
      if (!silent) {
        _showSnackBar('Gửi nhắc hóa đơn thất bại.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sendingKeys.remove(key));
      }
    }
  }

  Future<void> _sendContractReminder(
    _QuickContractReminder reminder, {
    bool silent = false,
  }) async {
    final hostId = _hostId;
    final tenant = reminder.tenant;
    if (hostId == null || tenant == null) return;

    final key = reminder.key;
    if (_sendingKeys.contains(key) || _sentQuickKeys.contains(key)) return;

    setState(() => _sendingKeys.add(key));
    try {
      await _notificationService.sendNotification(
        hostId: hostId,
        tenantId: tenant.userId,
        type: 'CONTRACT_EXPIRING',
        title: 'Thông báo hợp đồng sắp hết hạn',
        body: _buildContractReminderBody(reminder.contract, reminder.daysLeft),
        refType: 'CONTRACT',
        refId: reminder.contract.contractId,
      );
      if (!mounted) return;
      setState(() => _sentQuickKeys.add(key));
      if (!silent) {
        _showSnackBar('Đã gửi nhắc hợp đồng cho ${tenant.fullName}.');
      }
    } catch (_) {
      if (!silent) {
        _showSnackBar('Gửi nhắc hợp đồng thất bại.', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sendingKeys.remove(key));
      }
    }
  }

  Future<void> _sendAllInvoiceReminders() async {
    if (_sendingAllInvoices) return;
    final reminders = _invoiceReminders
        .where(
          (item) => item.tenant != null && !_sentQuickKeys.contains(item.key),
        )
        .toList();
    if (reminders.isEmpty) {
      _showSnackBar(
        'Không có hóa đơn quá hạn nào đủ dữ liệu để gửi.',
        isError: true,
      );
      return;
    }

    setState(() => _sendingAllInvoices = true);
    var sentCount = 0;
    try {
      for (final reminder in reminders) {
        await _sendInvoiceReminder(reminder, silent: true);
        if (_sentQuickKeys.contains(reminder.key)) {
          sentCount++;
        }
      }
      _showSnackBar(
        'Đã gửi $sentCount/${reminders.length} nhắc hóa đơn quá hạn.',
      );
    } finally {
      if (mounted) {
        setState(() => _sendingAllInvoices = false);
      }
    }
  }

  Future<void> _sendAllContractReminders() async {
    if (_sendingAllContracts) return;
    final reminders = _contractReminders
        .where(
          (item) => item.tenant != null && !_sentQuickKeys.contains(item.key),
        )
        .toList();
    if (reminders.isEmpty) {
      _showSnackBar(
        'Không có hợp đồng sắp hết hạn nào đủ dữ liệu để gửi.',
        isError: true,
      );
      return;
    }

    setState(() => _sendingAllContracts = true);
    var sentCount = 0;
    try {
      for (final reminder in reminders) {
        await _sendContractReminder(reminder, silent: true);
        if (_sentQuickKeys.contains(reminder.key)) {
          sentCount++;
        }
      }
      _showSnackBar(
        'Đã gửi $sentCount/${reminders.length} nhắc hợp đồng sắp hết hạn.',
      );
    } finally {
      if (mounted) {
        setState(() => _sendingAllContracts = false);
      }
    }
  }

  String _buildInvoiceReminderBody(InvoiceModel invoice) {
    final amount = CurrencyUtils.format(invoice.totalAmount);
    final period = AppDateUtils.formatMonthYear(
      invoice.billingMonth,
      invoice.billingYear,
    );
    final room = invoice.roomCode.isEmpty
        ? ''
        : ' cho phòng ${invoice.roomCode}';
    return 'Hóa đơn ${invoice.invoiceCode} kỳ $period$room hiện đã quá hạn thanh toán. '
        'Số tiền cần thanh toán là $amount. Vui lòng kiểm tra và hoàn tất thanh toán sớm.';
  }

  String _buildContractReminderBody(ContractModel contract, int daysLeft) {
    final endDate = AppDateUtils.formatDate(contract.endDate);
    final dayLabel = daysLeft == 0 ? 'hôm nay' : 'sau $daysLeft ngày';
    final room = contract.roomCode.isEmpty ? '' : ' phòng ${contract.roomCode}';
    return 'Hợp đồng ${contract.contractCode}$room sẽ hết hạn $dayLabel'
        '${endDate.isEmpty ? '' : ' vào ngày $endDate'}. '
        'Vui lòng liên hệ chủ trọ nếu cần gia hạn hoặc trao đổi thêm.';
  }

  void _onInboxSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => context.read<HostNotificationListProvider>().applyFilters(
        isRead: context.read<HostNotificationListProvider>().isRead,
        search: value,
      ),
    );
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

  IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'HOST_ANNOUNCEMENT':
        return Icons.campaign_outlined;
      case 'INVOICE_DUE':
      case 'INVOICE_OVERDUE':
        return Icons.receipt_long_outlined;
      case 'CONTRACT_EXPIRING':
      case 'CONTRACT_EXPIRED':
        return Icons.description_outlined;
      case 'ISSUE_UPDATED':
        return Icons.report_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'HOST_ANNOUNCEMENT':
        return AppColors.accent;
      case 'INVOICE_DUE':
        return AppColors.warning;
      case 'INVOICE_OVERDUE':
        return AppColors.error;
      case 'CONTRACT_EXPIRING':
      case 'CONTRACT_EXPIRED':
        return AppColors.info;
      case 'ISSUE_UPDATED':
        return AppColors.success;
      default:
        return AppColors.accent;
    }
  }

  String _labelForType(String type) {
    for (final option in _typeOptions) {
      if (option.value == type) return option.label;
    }
    return type;
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    Color? fillColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inputFill =
        fillColor ?? (isDark ? AppColors.darkCard : AppColors.lightCard);
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: subtext),
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final unreadCount = _isInboxMode
        ? context.select<HostNotificationListProvider, int>(
            (provider) => provider.unreadCount,
          )
        : 0;
    final markingAllRead = _isInboxMode
        ? context.select<HostNotificationListProvider, bool>(
            (provider) => provider.markingAllRead,
          )
        : false;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/host/dashboard');
          },
        ),
        title: Text(
          _isInboxMode
              ? 'Hộp thư thông báo${unreadCount > 0 ? ' ($unreadCount)' : ''}'
              : 'Trung tâm gửi thông báo',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          IconButton(
            tooltip: _isInboxMode ? 'Gửi thông báo' : 'Xem hộp thư',
            onPressed: () {
              if (_isInboxMode) {
                context.push('/host/notifications/send');
                return;
              }
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go('/host/notifications');
            },
            icon: Icon(
              _isInboxMode ? Icons.campaign_outlined : Icons.inbox_outlined,
              color: AppColors.accent,
            ),
          ),
          if (_isInboxMode && unreadCount > 0)
            TextButton(
              onPressed: markingAllRead ? null : _markAllRead,
              child: Text(
                markingAllRead ? 'Đang xử lý...' : 'Đọc hết',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        bottom: _isSendCenterMode
            ? TabBar(
                controller: _tabController,
                labelColor: AppColors.accent,
                unselectedLabelColor: subtext,
                indicatorColor: AppColors.accent,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: _tabLabels.map((item) => Tab(text: item)).toList(),
              )
            : null,
      ),
      body: _isInboxMode
          ? _buildInboxBody()
          : _loading
          ? const AppLoading()
          : _error != null
          ? ErrorRetryWidget(message: _error!, onRetry: _load)
          : TabBarView(
              controller: _tabController,
              children: [_buildComposeTab(), _buildQuickSendTab()],
            ),
      bottomNavigationBar: const HostBottomNav(currentIndex: 0),
    );
  }

  Widget _buildInboxBody() {
    return _HostNotificationInboxBody(
      hostId: _hostId,
      error: _error,
      searchController: _searchController,
      readFilters: _readFilters,
      onRetryLoad: _load,
      onSearchChanged: _onInboxSearchChanged,
      onRefreshInbox: () async {
        await context.read<HostNotificationListProvider>().refresh();
        _syncUnreadBadge();
      },
      onLoadMoreNotifications: _loadMoreNotifications,
      onOpenNotification: _openNotification,
      colorForType: _colorForType,
      iconForType: _iconForType,
      labelForType: _labelForType,
      buildInboxTab: _buildInboxTab,
    );
  }

  Widget _buildInboxTab(HostNotificationListProvider provider) {
    final state = provider.state;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async {
        await context.read<HostNotificationListProvider>().refresh();
        _syncUnreadBadge();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _InboxSummarySection(
            totalItems: state.totalItems,
            unreadCount: provider.unreadCount,
          ),
          const SizedBox(height: 16),
          _InboxFiltersSection(
            controller: _searchController,
            readFilters: _readFilters,
            selectedRead: provider.isRead,
            onSearchChanged: _onInboxSearchChanged,
            onReadFilterChanged: (value) {
              context.read<HostNotificationListProvider>().applyFilters(
                isRead: value,
                search: _searchController.text,
              );
            },
          ),
          const SizedBox(height: 16),
          if (state.items.isEmpty)
            const AppEmpty(
              message: 'Chưa có thông báo nào.',
              icon: Icons.notifications_outlined,
            )
          else
            ...state.items.map(
              (notification) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NotificationCard(
                  notification: notification,
                  color: _colorForType(notification.type),
                  icon: _iconForType(notification.type),
                  isReading: provider.readingIds.contains(
                    notification.notificationId,
                  ),
                  typeLabel: _labelForType(notification.type),
                  onTap: () => _openNotification(notification),
                ),
              ),
            ),
          if (state.hasNext || state.loadingMore)
            PagedLoadMore(
              loading: state.loadingMore,
              hasNext: state.hasNext,
              onPressed: _loadMoreNotifications,
            ),
        ],
      ),
    );
  }

  Widget _buildComposeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          AppCard(
            featured: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gửi thông báo thủ công',
                  style: AppTextStyles.h3.copyWith(color: fg),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn người nhận, loại thông báo và nội dung để gửi ngay từ hệ thống.',
                  style: AppTextStyles.bodySmall.copyWith(color: subtext),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Người nhận',
                  style: AppTextStyles.body.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả người thuê đang ở'),
                      selected: _recipientMode == 'ALL',
                      onSelected: (_) {
                        setState(() {
                          _recipientMode = 'ALL';
                          _selectedTenantId = null;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Chọn một người nhận'),
                      selected: _recipientMode == 'ONE',
                      onSelected: (_) {
                        setState(() {
                          _recipientMode = 'ONE';
                          _selectedTenantId ??= _activeTenants.isEmpty
                              ? null
                              : _activeTenants.first.userId;
                        });
                      },
                    ),
                  ],
                ),
                if (_recipientMode == 'ONE') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedTenantId,
                    decoration: _inputDecoration(
                      label: 'Chọn người nhận',
                      hint: 'Chọn người thuê nhận thông báo',
                    ),
                    items: _activeTenants
                        .map(
                          (tenant) => DropdownMenuItem<int>(
                            value: tenant.userId,
                            child: Text(
                              '${tenant.fullName}${(tenant.currentRoomCode ?? '').isEmpty ? '' : ' - ${tenant.currentRoomCode}'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedTenantId = value);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: _inputDecoration(
                    label: 'Loại thông báo',
                    hint: 'Chọn loại thông báo',
                  ),
                  items: _typeOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.value,
                          child: Text(option.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: _inputDecoration(
                    label: 'Tiêu đề',
                    hint: 'Ví dụ: Thông báo lịch bảo trì điện nước',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bodyController,
                  maxLines: 6,
                  decoration: _inputDecoration(
                    label: 'Nội dung',
                    hint: 'Nhập nội dung thông báo gửi đến người thuê',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hiện có ${_activeTenants.length} người thuê đủ điều kiện nhận thông báo.',
                  style: AppTextStyles.bodySmall.copyWith(color: subtext),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: _recipientMode == 'ALL'
                      ? 'Gửi cho tất cả người thuê đang ở'
                      : 'Gửi cho người nhận đã chọn',
                  icon: Icons.send_rounded,
                  loading: _sendingManual,
                  onPressed: _sendingManual ? null : _sendManualNotification,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSendTab() {
    final invoiceReminders = _invoiceReminders;
    final contractReminders = _contractReminders;
    final unresolvedCount =
        invoiceReminders.where((item) => item.tenant == null).length +
        contractReminders.where((item) => item.tenant == null).length;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          AppCard(
            featured:
                invoiceReminders.isNotEmpty || contractReminders.isNotEmpty,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.error,
                  label: '${invoiceReminders.length} hóa đơn quá hạn',
                ),
                _MetricChip(
                  icon: Icons.description_outlined,
                  color: AppColors.info,
                  label: '${contractReminders.length} hợp đồng sắp hết hạn',
                ),
                _MetricChip(
                  icon: Icons.link_off_rounded,
                  color: unresolvedCount == 0
                      ? AppColors.success
                      : AppColors.warning,
                  label: unresolvedCount == 0
                      ? 'Dữ liệu người nhận đã đầy đủ'
                      : '$unresolvedCount mục còn thiếu người nhận',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (unresolvedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppCard(
                featured: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Một số mục chưa đủ thông tin người nhận nên chưa thể gửi tự động. Hãy kiểm tra lại người thuê và phòng tương ứng.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          _buildQuickInvoiceSection(invoiceReminders),
          const SizedBox(height: 16),
          _buildQuickContractSection(contractReminders),
        ],
      ),
    );
  }

  Widget _buildQuickInvoiceSection(List<_QuickInvoiceReminder> reminders) {
    final sendableCount = reminders
        .where(
          (item) => item.tenant != null && !_sentQuickKeys.contains(item.key),
        )
        .length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationSectionHeader(
            title: 'Nhắc nhanh hóa đơn quá hạn',
            subtitle:
                'Gửi trực tiếp cho từng người thuê còn hóa đơn chưa thanh toán.',
            actionLabel: 'Gửi tất cả',
            loading: _sendingAllInvoices,
            enabled: sendableCount > 0,
            onPressed: _sendAllInvoiceReminders,
          ),
          const SizedBox(height: 16),
          if (reminders.isEmpty)
            const AppEmpty(
              message: 'Không có hóa đơn quá hạn nào để gửi nhắc.',
              icon: Icons.receipt_long_outlined,
            )
          else
            ...reminders.map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuickReminderCard(
                  title: reminder.invoice.invoiceCode,
                  subtitle:
                      '${reminder.invoice.tenantName} - Phòng ${reminder.invoice.roomCode}',
                  meta: AppDateUtils.formatMonthYear(
                    reminder.invoice.billingMonth,
                    reminder.invoice.billingYear,
                  ),
                  valueText: CurrencyUtils.format(reminder.invoice.totalAmount),
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.error,
                  unresolved: reminder.tenant == null,
                  unresolvedText:
                      'Chưa xác định được người nhận cho hóa đơn này.',
                  trailingLabel: _sentQuickKeys.contains(reminder.key)
                      ? 'Đã gửi'
                      : 'Gửi nhắc',
                  trailingLoading: _sendingKeys.contains(reminder.key),
                  trailingEnabled:
                      reminder.tenant != null &&
                      !_sentQuickKeys.contains(reminder.key),
                  onPressed: () => _sendInvoiceReminder(reminder),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickContractSection(List<_QuickContractReminder> reminders) {
    final sendableCount = reminders
        .where(
          (item) => item.tenant != null && !_sentQuickKeys.contains(item.key),
        )
        .length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationSectionHeader(
            title: 'Nhắc nhanh hợp đồng sắp hết hạn',
            subtitle: 'Các hợp đồng còn tối đa 30 ngày sẽ xuất hiện tại đây.',
            actionLabel: 'Gửi tất cả',
            loading: _sendingAllContracts,
            enabled: sendableCount > 0,
            onPressed: _sendAllContractReminders,
          ),
          const SizedBox(height: 16),
          if (reminders.isEmpty)
            const AppEmpty(
              message: 'Không có hợp đồng nào sắp hết hạn.',
              icon: Icons.description_outlined,
            )
          else
            ...reminders.map(
              (reminder) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuickReminderCard(
                  title: reminder.contract.contractCode,
                  subtitle:
                      '${reminder.contract.tenantName} - Phòng ${reminder.contract.roomCode}',
                  meta: reminder.daysLeft == 0
                      ? 'Hết hạn hôm nay'
                      : 'Còn ${reminder.daysLeft} ngày',
                  valueText: AppDateUtils.formatDate(reminder.contract.endDate),
                  icon: Icons.description_outlined,
                  iconColor: AppColors.info,
                  unresolved: reminder.tenant == null,
                  unresolvedText:
                      'Chưa xác định được người nhận cho hợp đồng này.',
                  trailingLabel: _sentQuickKeys.contains(reminder.key)
                      ? 'Đã gửi'
                      : 'Gửi nhắc',
                  trailingLoading: _sendingKeys.contains(reminder.key),
                  trailingEnabled:
                      reminder.tenant != null &&
                      !_sentQuickKeys.contains(reminder.key),
                  onPressed: () => _sendContractReminder(reminder),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationSectionHeader extends StatelessWidget {
  const _NotificationSectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return LayoutBuilder(
      builder: (context, constraints) {
        final action = AppButton(
          label: actionLabel,
          fullWidth: false,
          height: 42,
          variant: AppButtonVariant.outlined,
          loading: loading,
          onPressed: enabled ? onPressed : null,
        );

        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h3.copyWith(color: fg)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(color: subtext),
              ),
              const SizedBox(height: 12),
              action,
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h3.copyWith(color: fg)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            action,
          ],
        );
      },
    );
  }
}

class _NotificationTypeOption {
  final String value;
  final String label;

  const _NotificationTypeOption({required this.value, required this.label});
}

class _ReadFilterOption {
  final String label;
  final bool? value;

  const _ReadFilterOption({required this.label, required this.value});
}

class _QuickInvoiceReminder {
  final InvoiceModel invoice;
  final TenantModel? tenant;

  const _QuickInvoiceReminder({required this.invoice, required this.tenant});

  String get key => 'invoice:${invoice.invoiceId}';
}

class _QuickContractReminder {
  final ContractModel contract;
  final int daysLeft;
  final TenantModel? tenant;

  const _QuickContractReminder({
    required this.contract,
    required this.daysLeft,
    required this.tenant,
  });

  String get key => 'contract:${contract.contractId}';
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.color,
    required this.label,
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
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostNotificationInboxBody extends StatelessWidget {
  final int? hostId;
  final String? error;
  final TextEditingController searchController;
  final List<_ReadFilterOption> readFilters;
  final Future<void> Function() onRetryLoad;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefreshInbox;
  final Future<void> Function() onLoadMoreNotifications;
  final Future<void> Function(NotificationModel notification)
  onOpenNotification;
  final Color Function(String type) colorForType;
  final IconData Function(String type) iconForType;
  final String Function(String type) labelForType;
  final Widget Function(HostNotificationListProvider provider) buildInboxTab;

  const _HostNotificationInboxBody({
    required this.hostId,
    required this.error,
    required this.searchController,
    required this.readFilters,
    required this.onRetryLoad,
    required this.onSearchChanged,
    required this.onRefreshInbox,
    required this.onLoadMoreNotifications,
    required this.onOpenNotification,
    required this.colorForType,
    required this.iconForType,
    required this.labelForType,
    required this.buildInboxTab,
  });

  @override
  Widget build(BuildContext context) {
    if (hostId == null && error == null) {
      return const AppLoading();
    }

    if (error != null) {
      return ErrorRetryWidget(message: error!, onRetry: onRetryLoad);
    }

    final provider = context.watch<HostNotificationListProvider>();
    final state = provider.state;

    if (state.loading) {
      return const AppLoading();
    }

    if (state.error != null) {
      return ErrorRetryWidget(
        message: state.error!,
        onRetry: () => context.read<HostNotificationListProvider>().refresh(),
      );
    }

    return buildInboxTab(provider);
  }
}

class _InboxSummarySection extends StatelessWidget {
  final int totalItems;
  final int unreadCount;

  const _InboxSummarySection({
    required this.totalItems,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      featured: unreadCount > 0,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricChip(
            icon: Icons.notifications_active_outlined,
            color: AppColors.accent,
            label: 'Tong $totalItems thong bao',
          ),
          _MetricChip(
            icon: Icons.mark_email_unread_outlined,
            color: AppColors.warning,
            label: '$unreadCount chua doc',
          ),
          _MetricChip(
            icon: Icons.mark_email_read_outlined,
            color: AppColors.success,
            label: '${(totalItems - unreadCount).clamp(0, totalItems)} da doc',
          ),
        ],
      ),
    );
  }
}

class _InboxFiltersSection extends StatelessWidget {
  final TextEditingController controller;
  final List<_ReadFilterOption> readFilters;
  final bool? selectedRead;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool?> onReadFilterChanged;

  const _InboxFiltersSection({
    required this.controller,
    required this.readFilters,
    required this.selectedRead,
    required this.onSearchChanged,
    required this.onReadFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListSearchField(
          controller: controller,
          hintText: 'Tìm trong thông báo...',
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: readFilters
              .map(
                (filter) => ChoiceChip(
                  label: Text(filter.label),
                  selected: selectedRead == filter.value,
                  onSelected: (_) => onReadFilterChanged(filter.value),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final Color color;
  final IconData icon;
  final bool isReading;
  final String typeLabel;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.color,
    required this.icon,
    required this.isReading,
    required this.typeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                : color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                  : color.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.body.copyWith(
                              color: fg,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      typeLabel,
                      style: AppTextStyles.caption.copyWith(color: color),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.body,
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          AppDateUtils.timeAgo(notification.createdAt),
                          style: AppTextStyles.caption.copyWith(color: subtext),
                        ),
                        const Spacer(),
                        if (isReading)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        else if (notification.refId != null)
                          Text(
                            'Mở chi tiết',
                            style: AppTextStyles.caption.copyWith(color: color),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReminderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  final String valueText;
  final IconData icon;
  final Color iconColor;
  final bool unresolved;
  final String unresolvedText;
  final String trailingLabel;
  final bool trailingLoading;
  final bool trailingEnabled;
  final VoidCallback onPressed;

  const _QuickReminderCard({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.valueText,
    required this.icon,
    required this.iconColor,
    required this.unresolved,
    required this.unresolvedText,
    required this.trailingLabel,
    required this.trailingLoading,
    required this.trailingEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: unresolved ? AppColors.warning : border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniPill(label: meta, color: iconColor),
                        _MiniPill(label: valueText, color: AppColors.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (unresolved) ...[
            const SizedBox(height: 12),
            Text(
              unresolvedText,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: trailingLabel,
              fullWidth: false,
              height: 40,
              variant: trailingEnabled
                  ? AppButtonVariant.filled
                  : AppButtonVariant.outlined,
              loading: trailingLoading,
              onPressed: trailingEnabled ? onPressed : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}
