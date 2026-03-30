import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';

class TenantInvoiceListScreen extends StatefulWidget {
  const TenantInvoiceListScreen({super.key});
  @override
  State<TenantInvoiceListScreen> createState() =>
      _TenantInvoiceListScreenState();
}

class _TenantInvoiceListScreenState extends State<TenantInvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int? _userId;

  final _tabs     = const ['Tất cả', 'Chưa TT', 'Quá hạn', 'Đã TT'];
  final _statuses = const ['', 'UNPAID', 'OVERDUE', 'PAID'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    _userId = await context.read<AuthProvider>().getUserId();
    if (_userId != null && mounted) {
      context.read<InvoiceProvider>().fetchInvoicesByTenant(_userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg      = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final provider = context.watch<InvoiceProvider>();

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
          labelStyle: AppTextStyles.bodySmall
              .copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTextStyles.bodySmall,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: provider.loading
          ? const AppLoading()
          : TabBarView(
        controller: _tab,
        children: List.generate(_tabs.length, (i) {
          final status = _statuses[i];
          final list   = status.isEmpty
              ? provider.invoices
              : provider.invoices
              .where((inv) => inv.status == status)
              .toList();
          if (list.isEmpty) {
            return const AppEmpty(
              message: 'Không có hóa đơn nào',
              icon: Icons.receipt_long_outlined,
            );
          }
          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, idx) =>
                  _InvoiceCard(invoice: list[idx], isDark: isDark),
            ),
          );
        }),
      ),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 1),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final bool isDark;
  const _InvoiceCard({required this.invoice, required this.isDark});

  Color get _statusColor {
    switch (invoice.status) {
      case 'PAID':    return AppColors.invoicePaid;
      case 'OVERDUE': return AppColors.invoiceOverdue;
      case 'UNPAID':  return AppColors.invoiceUnpaid;
      default:        return AppColors.invoiceDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg      = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border  = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AppCard(
      featured: invoice.status == 'OVERDUE',
      onTap: () => context.push('/tenant/invoices/${invoice.invoiceId}'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_outlined,
                color: _statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(invoice.invoiceCode,
                  style: AppTextStyles.body
                      .copyWith(color: fg, fontWeight: FontWeight.w600)),
              Text(AppDateUtils.formatMonthYear(
                  invoice.billingMonth, invoice.billingYear),
                  style: AppTextStyles.bodySmall.copyWith(color: subtext)),
            ],
          )),
          StatusBadge(status: invoice.status),
        ]),
        Divider(color: border, height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(CurrencyUtils.format(invoice.totalAmount),
              style: AppTextStyles.h3.copyWith(color: _statusColor)),
          Icon(Icons.chevron_right_rounded, color: subtext, size: 18),
        ]),
      ]),
    );
  }
}