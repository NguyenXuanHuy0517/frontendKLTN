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
import '../../../providers/auth_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = await context.read<AuthProvider>().getUserId();
      if (!mounted || userId == null) return;
      // FIX: dùng tenant endpoint
      context.read<InvoiceProvider>()
          .fetchInvoiceDetailByTenant(widget.invoiceId, userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final invoice = context.watch<InvoiceProvider>().selected;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          invoice?.invoiceCode ?? 'Chi tiết hóa đơn',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
      ),
      body: invoice == null
          ? const AppLoading()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ────────────────────────────
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppDateUtils.formatMonthYear(
                                invoice.billingMonth,
                                invoice.billingYear),
                            style: AppTextStyles.h3.copyWith(color: fg),
                          ),
                          if (invoice.roomCode.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Phòng ${invoice.roomCode}',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: subtext),
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusBadge(status: invoice.status),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    CurrencyUtils.format(invoice.totalAmount),
                    style: AppTextStyles.h1.copyWith(
                        color: AppColors.accent, fontSize: 28),
                  ),
                  if (invoice.status == 'UNPAID' ||
                      invoice.status == 'OVERDUE') ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14,
                          color: invoice.status == 'OVERDUE'
                              ? AppColors.error
                              : AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        invoice.status == 'OVERDUE'
                            ? 'Hóa đơn đã quá hạn thanh toán'
                            : 'Vui lòng thanh toán cho chủ trọ',
                        style: AppTextStyles.bodySmall.copyWith(
                            color: invoice.status == 'OVERDUE'
                                ? AppColors.error
                                : AppColors.warning),
                      ),
                    ]),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Chi tiết thanh toán ──────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết thanh toán',
                    style: AppTextStyles.body.copyWith(
                        color: fg, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    label: 'Tiền phòng',
                    value: CurrencyUtils.format(invoice.rentAmount),
                    fg: fg,
                    subtext: subtext,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    label:
                    'Tiền điện (${invoice.elecOld}→${invoice.elecNew} kWh)',
                    value: CurrencyUtils.format(invoice.elecAmount),
                    fg: fg,
                    subtext: subtext,
                  ),
                  if (invoice.elecPrice > 0) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: Text(
                        'Đơn giá: ${CurrencyUtils.format(invoice.elecPrice)}/kWh',
                        style: AppTextStyles.caption
                            .copyWith(color: subtext),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _DetailRow(
                    label:
                    'Tiền nước (${invoice.waterOld}→${invoice.waterNew} m³)',
                    value: CurrencyUtils.format(invoice.waterAmount),
                    fg: fg,
                    subtext: subtext,
                  ),
                  if (invoice.waterPrice > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Đơn giá: ${CurrencyUtils.format(invoice.waterPrice)}/m³',
                      style:
                      AppTextStyles.caption.copyWith(color: subtext),
                    ),
                  ],
                  if (invoice.serviceAmount > 0) ...[
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Dịch vụ',
                      value: CurrencyUtils.format(invoice.serviceAmount),
                      fg: fg,
                      subtext: subtext,
                    ),
                    if (invoice.serviceNames.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 6,
                          children: invoice.serviceNames
                              .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                              AppColors.accent.withOpacity(0.08),
                              borderRadius:
                              BorderRadius.circular(6),
                            ),
                            child: Text(s,
                                style:
                                AppTextStyles.caption.copyWith(
                                    color: AppColors.accent)),
                          ))
                              .toList(),
                        ),
                      ),
                  ],
                  Divider(color: border, height: 20),
                  _DetailRow(
                    label: 'Tổng cộng',
                    value: CurrencyUtils.format(invoice.totalAmount),
                    fg: AppColors.accent,
                    subtext: subtext,
                    bold: true,
                  ),
                ],
              ),
            ),

            // ── Thời hạn thanh toán ──────────────────────
            if (invoice.dueDate != null &&
                (invoice.status == 'UNPAID' ||
                    invoice.status == 'OVERDUE')) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Row(children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: invoice.status == 'OVERDUE'
                        ? AppColors.error
                        : AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hạn thanh toán',
                        style:
                        AppTextStyles.caption.copyWith(color: subtext),
                      ),
                      Text(
                        AppDateUtils.formatDate(invoice.dueDate),
                        style: AppTextStyles.body.copyWith(
                          color: invoice.status == 'OVERDUE'
                              ? AppColors.error
                              : AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ]),
              ),
            ],

            // ── Đã thanh toán ────────────────────────────
            if (invoice.status == 'PAID' && invoice.paidAt != null) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.invoicePaid, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đã thanh toán lúc ${AppDateUtils.formatDateTime(invoice.paidAt)}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.invoicePaid),
                    ),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color fg, subtext;
  final bool bold;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.fg,
    required this.subtext,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: bold ? fg : subtext,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
      Text(
        value,
        style: AppTextStyles.bodySmall.copyWith(
          color: fg,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    ],
  );
}