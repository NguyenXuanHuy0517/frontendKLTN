import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/error_retry_widget.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/list_search_field.dart';
import '../../../core/widgets/paged_load_more.dart';
import '../../../core/widgets/payment_status_chip.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/host_invoice_list_provider.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  final _tabs = const [
    'Tất cả',
    'Chưa thanh toán',
    'Quá hạn',
    'Đã thanh toán',
  ];
  final _statuses = const ['', 'UNPAID', 'OVERDUE', 'PAID'];
  final _monthOptions = List.generate(
    13,
    (index) => _IntFilterOption(
      value: index,
      label: index == 0 ? 'Tất cả tháng' : 'Tháng $index',
    ),
  );
  final _searchController = TextEditingController();

  late final TabController _tabCtrl;

  int? _hostId;
  Timer? _searchDebounce;
  String? _bootstrapError;

  String get _currentStatus => _statuses[_tabCtrl.index];

  List<_IntFilterOption> get _yearOptions {
    final currentYear = DateTime.now().year;
    return [
      const _IntFilterOption(value: 0, label: 'Tất cả năm'),
      for (final year in [currentYear + 1, currentYear, currentYear - 1])
        _IntFilterOption(value: year, label: '$year'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(_handleTabChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabCtrl
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final hostId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    if (hostId == null) {
      setState(() {
        _bootstrapError =
            'Không xác định được tài khoản chủ trọ hiện tại.';
      });
      return;
    }

    _hostId = hostId;
    final provider = context.read<HostInvoiceListProvider>();
    final initialTab = _statuses.indexOf(provider.status);
    if (initialTab >= 0 && _tabCtrl.index != initialTab) {
      _tabCtrl.index = initialTab;
    }
    _searchController.text = provider.search;
    await provider.bootstrap(hostId: hostId);
  }

  void _handleTabChanged() {
    if (_tabCtrl.indexIsChanging || _hostId == null) return;
    context.read<HostInvoiceListProvider>().applyFilters(
      status: _currentStatus,
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => context.read<HostInvoiceListProvider>().applyFilters(search: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Hóa đơn', style: AppTextStyles.h3.copyWith(color: fg)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: subtext,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.bodySmall,
          tabs: _tabs.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: _buildBody(isDark),
      bottomNavigationBar: const HostBottomNav(currentIndex: 3),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_bootstrapError != null) {
      return ErrorRetryWidget(message: _bootstrapError!, onRetry: _bootstrap);
    }

    final provider = context.watch<HostInvoiceListProvider>();
    final state = provider.state;

    if (state.loading) {
      return const AppLoading();
    }

    if (state.error != null) {
      return ErrorRetryWidget(
        message: state.error!,
        onRetry: () => context.read<HostInvoiceListProvider>().refresh(),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<HostInvoiceListProvider>().refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        itemCount:
            2 +
            (state.items.isEmpty ? 1 : state.items.length) +
            ((state.hasNext || state.loadingMore) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListSearchField(
                controller: _searchController,
                hintText: 'Tìm theo mã hóa đơn, người thuê, phòng...',
                onChanged: _onSearchChanged,
              ),
            );
          }

          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _InvoiceFilterDropdown(
                      label: 'Tháng',
                      value: provider.month ?? 0,
                      options: _monthOptions,
                      onChanged: (value) {
                        context.read<HostInvoiceListProvider>().applyFilters(
                          month: value == 0 ? null : value,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InvoiceFilterDropdown(
                      label: 'Năm',
                      value: provider.year ?? 0,
                      options: _yearOptions,
                      onChanged: (value) {
                        context.read<HostInvoiceListProvider>().applyFilters(
                          year: value == 0 ? null : value,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          if (state.items.isEmpty) {
            return const AppEmpty(
              message: 'Không có hóa đơn nào',
              icon: Icons.receipt_long_outlined,
            );
          }

          final itemIndex = index - 2;
          if (itemIndex == state.items.length) {
            return PagedLoadMore(
              loading: state.loadingMore,
              hasNext: state.hasNext,
              onPressed: () =>
                  context.read<HostInvoiceListProvider>().loadMore(),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _InvoiceCard(
              invoice: state.items[itemIndex],
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isDark;

  const _InvoiceCard({required this.invoice, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Color statusColor;
    switch (invoice.status) {
      case 'PAID':
        statusColor = AppColors.invoicePaid;
        break;
      case 'OVERDUE':
        statusColor = AppColors.invoiceOverdue;
        break;
      case 'UNPAID':
        statusColor = AppColors.invoiceUnpaid;
        break;
      default:
        statusColor = AppColors.invoiceDraft;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/host/invoices/${invoice.invoiceId}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
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
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.invoiceCode,
                          style: AppTextStyles.body.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${invoice.tenantName} • Phòng ${invoice.roomCode}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: subtext,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((invoice.paymentStatus ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          PaymentStatusChip(status: invoice.paymentStatus),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge(status: invoice.status),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: border, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng tiền',
                        style: AppTextStyles.caption.copyWith(color: subtext),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.format(invoice.totalAmount),
                        style: AppTextStyles.h3.copyWith(color: statusColor),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Kỳ thanh toán',
                        style: AppTextStyles.caption.copyWith(color: subtext),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppDateUtils.formatMonthYear(
                          invoice.billingMonth,
                          invoice.billingYear,
                        ),
                        style: AppTextStyles.body.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (invoice.hasPaymentProof) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 68,
                          height: 68,
                          child: Image.network(
                            invoice.paymentProofUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: border,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Có minh chứng chuyển khoản',
                              style: AppTextStyles.body.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              invoice.paymentSubmittedAt != null
                                  ? 'Gửi ${AppDateUtils.timeAgo(invoice.paymentSubmittedAt)}'
                                  : 'Người thuê đã gửi ảnh xác nhận.',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: subtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceFilterDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<_IntFilterOption> options;
  final ValueChanged<int?> onChanged;

  const _InvoiceFilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fillColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<int>(
              value: option.value,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _IntFilterOption {
  final int value;
  final String label;

  const _IntFilterOption({required this.value, required this.label});
}
