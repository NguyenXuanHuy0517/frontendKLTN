import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/invoice_provider.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  int? _hostId;
  late TabController _tabCtrl;

  final _tabs = const ['Tất cả', 'Chưa thanh toán', 'Quá hạn', 'Đã thanh toán'];
  final _statuses = ['', 'UNPAID', 'OVERDUE', 'PAID'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _hostId = await context.read<AuthProvider>().getUserId();
    if (_hostId != null && mounted) {
      context.read<InvoiceProvider>().fetchInvoices(_hostId!);
    }
  }

  List<InvoiceModel> _filtered(List<InvoiceModel> invoices, int tabIndex) {
    final status = _statuses[tabIndex];
    if (status.isEmpty) return invoices;
    return invoices.where((i) => i.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final provider = context.watch<InvoiceProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Hóa đơn',
            style: AppTextStyles.h3.copyWith(color: fg)),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: subtext,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle:
          AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTextStyles.bodySmall,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: provider.loading
          ? const AppLoading()
          : TabBarView(
        controller: _tabCtrl,
        children: List.generate(
          _tabs.length,
              (i) {
            final list = _filtered(provider.invoices, i);
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
                separatorBuilder: (context, separatorIndex) =>
                const SizedBox(height: 12),
                itemBuilder: (context, index) => _InvoiceCard(
                  invoice: list[index],
                  isDark: isDark,
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const HostBottomNav(currentIndex: 3),
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

    return AppCard(
      featured: invoice.status == 'OVERDUE',
      onTap: () => context.push('/host/invoices/${invoice.invoiceId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
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
                      '${invoice.tenantName} — Phòng ${invoice.roomCode}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: subtext),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: invoice.status),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: border, height: 1),
          const SizedBox(height: 16),

          // Amount + Period
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng tiền',
                      style: AppTextStyles.caption.copyWith(color: subtext)),
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
                  Text('Kỳ thanh toán',
                      style: AppTextStyles.caption.copyWith(color: subtext)),
                  const SizedBox(height: 4),
                  Text(
                    AppDateUtils.formatMonthYear(
                        invoice.billingMonth, invoice.billingYear),
                    style: AppTextStyles.body.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
