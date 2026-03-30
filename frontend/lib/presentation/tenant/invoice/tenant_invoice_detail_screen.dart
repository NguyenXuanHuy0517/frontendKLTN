import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/invoice_provider.dart';

class TenantInvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;
  const TenantInvoiceDetailScreen({super.key, required this.invoiceId});
  @override
  State<TenantInvoiceDetailScreen> createState() =>
      _TenantInvoiceDetailScreenState();
}

class _TenantInvoiceDetailScreenState
    extends State<TenantInvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<InvoiceProvider>().fetchInvoiceDetail(widget.invoiceId));
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg       = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext  = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border   = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final invoice  = context.watch<InvoiceProvider>().selected;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(invoice?.invoiceCode ?? 'Chi tiết hóa đơn',
            style: AppTextStyles.h3.copyWith(color: fg)),
      ),
      body: invoice == null
          ? const AppLoading()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(
                      AppDateUtils.formatMonthYear(
                          invoice.billingMonth, invoice.billingYear),
                      style: AppTextStyles.h3.copyWith(color: fg),
                    )),
                    StatusBadge(status: invoice.status),
                  ]),
                  const SizedBox(height: 12),
                  Text(CurrencyUtils.format(invoice.totalAmount),
                      style: AppTextStyles.h1.copyWith(
                          color: AppColors.accent, fontSize: 28)),
                  if (invoice.status == 'UNPAID' ||
                      invoice.status == 'OVERDUE')
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Vui lòng thanh toán cho chủ trọ trực tiếp',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: subtext),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Chi tiết
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chi tiết thanh toán',
                      style: AppTextStyles.body.copyWith(
                          color: fg, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _Row('Tiền phòng',
                      CurrencyUtils.format(invoice.rentAmount),
                      fg, subtext),
                  const SizedBox(height: 8),
                  _Row(
                    'Tiền điện '
                        '(${invoice.elecOld}→${invoice.elecNew} kWh)',
                    CurrencyUtils.format(invoice.elecAmount),
                    fg, subtext,
                  ),
                  const SizedBox(height: 8),
                  _Row(
                    'Tiền nước '
                        '(${invoice.waterOld}→${invoice.waterNew} m³)',
                    CurrencyUtils.format(invoice.waterAmount),
                    fg, subtext,
                  ),
                  if (invoice.serviceAmount > 0) ...[
                    const SizedBox(height: 8),
                    _Row('Dịch vụ',
                        CurrencyUtils.format(invoice.serviceAmount),
                        fg, subtext),
                  ],
                  Divider(color: border, height: 20),
                  _Row('Tổng cộng',
                      CurrencyUtils.format(invoice.totalAmount),
                      AppColors.accent, subtext,
                      bold: true),
                ],
              ),
            ),

            if (invoice.status == 'PAID' &&
                invoice.paidAt != null) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.invoicePaid, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Đã thanh toán lúc '
                        '${AppDateUtils.formatDateTime(invoice.paidAt)}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.invoicePaid),
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color valueColor, labelColor;
  final bool bold;
  const _Row(this.label, this.value, this.valueColor, this.labelColor,
      {this.bold = false});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: AppTextStyles.bodySmall.copyWith(
              color: bold ? valueColor : labelColor,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
      Text(value,
          style: AppTextStyles.bodySmall.copyWith(
              color: valueColor,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
    ],
  );
}