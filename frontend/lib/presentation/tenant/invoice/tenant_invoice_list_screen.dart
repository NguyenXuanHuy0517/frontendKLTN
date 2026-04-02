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
import '../../../core/widgets/list_search_field.dart';
import '../../../core/widgets/paged_load_more.dart';
import '../../../core/widgets/payment_status_chip.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tenant_invoice_list_provider.dart';

class TenantInvoiceListScreen extends StatefulWidget {
  const TenantInvoiceListScreen({super.key});

  @override
  State<TenantInvoiceListScreen> createState() =>
      _TenantInvoiceListScreenState();
}

class _TenantInvoiceListScreenState extends State<TenantInvoiceListScreen>
    with SingleTickerProviderStateMixin {
  final _tabs = const [
    'Tất cả',
    'Chưa thanh toán',
    'Quá hạn',
    'Đã thanh toán',
  ];
  final _statuses = const ['', 'UNPAID', 'OVERDUE', 'PAID'];
  final _searchController = TextEditingController();

  late final TabController _tab;

  int? _userId;
  Timer? _searchDebounce;
  String? _bootstrapError;

  String get _currentStatus => _statuses[_tab.index];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(_handleTabChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tab
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    if (userId == null) {
      setState(() {
        _bootstrapError =
            'Không xác định được tài khoản người thuê hiện tại.';
      });
      return;
    }

    _userId = userId;
    final provider = context.read<TenantInvoiceListProvider>();
    final initialTab = _statuses.indexOf(provider.status);
    if (initialTab >= 0 && _tab.index != initialTab) {
      _tab.index = initialTab;
    }
    _searchController.text = provider.search;
    await provider.bootstrap(userId: userId);
  }

  void _handleTabChanged() {
    if (_tab.indexIsChanging || _userId == null) return;
    context.read<TenantInvoiceListProvider>().applyFilters(
      status: _currentStatus,
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () =>
          context.read<TenantInvoiceListProvider>().applyFilters(search: value),
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
        title: Text('Hóa đơn', style: AppTextStyles.h3.copyWith(color: fg)),
        bottom: TabBar(
          controller: _tab,
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
      bottomNavigationBar: const TenantBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_bootstrapError != null) {
      return ErrorRetryWidget(message: _bootstrapError!, onRetry: _bootstrap);
    }

    final state = context.watch<TenantInvoiceListProvider>().state;
    if (state.loading) {
      return const AppLoading();
    }

    if (state.error != null) {
      return ErrorRetryWidget(
        message: state.error!,
        onRetry: () => context.read<TenantInvoiceListProvider>().refresh(),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<TenantInvoiceListProvider>().refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        itemCount:
            1 +
            (state.items.isEmpty ? 1 : state.items.length) +
            ((state.hasNext || state.loadingMore) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListSearchField(
                controller: _searchController,
                hintText: 'Tìm theo mã hóa đơn...',
                onChanged: _onSearchChanged,
              ),
            );
          }

          if (state.items.isEmpty) {
            return const AppEmpty(
              message: 'Không có hóa đơn nào',
              icon: Icons.receipt_long_outlined,
            );
          }

          final itemIndex = index - 1;
          if (itemIndex == state.items.length) {
            return PagedLoadMore(
              loading: state.loadingMore,
              hasNext: state.hasNext,
              onPressed: () =>
                  context.read<TenantInvoiceListProvider>().loadMore(),
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

  Color get _statusColor {
    switch (invoice.status) {
      case 'PAID':
        return AppColors.invoicePaid;
      case 'OVERDUE':
        return AppColors.invoiceOverdue;
      case 'UNPAID':
        return AppColors.invoiceUnpaid;
      default:
        return AppColors.invoiceDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/tenant/invoices/${invoice.invoiceId}'),
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
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: _statusColor,
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
                          AppDateUtils.formatMonthYear(
                            invoice.billingMonth,
                            invoice.billingYear,
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: subtext,
                          ),
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
              Divider(color: border, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CurrencyUtils.format(invoice.totalAmount),
                          style: AppTextStyles.h3.copyWith(color: _statusColor),
                        ),
                        if (invoice.hasPaymentProof) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Đã gửi minh chứng ${AppDateUtils.timeAgo(invoice.paymentSubmittedAt)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: subtext,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: subtext, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
