import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/payment_status_chip.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/host_invoice_list_provider.dart';
import '../../../providers/invoice_provider.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _elecOldCtrl = TextEditingController();
  final _elecNewCtrl = TextEditingController();
  final _waterOldCtrl = TextEditingController();
  final _waterNewCtrl = TextEditingController();
  bool _editingMeters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().fetchInvoiceDetail(widget.invoiceId);
    });
  }

  @override
  void dispose() {
    _elecOldCtrl.dispose();
    _elecNewCtrl.dispose();
    _waterOldCtrl.dispose();
    _waterNewCtrl.dispose();
    super.dispose();
  }

  void _prefillMeters() {
    final invoice = context.read<InvoiceProvider>().selected;
    if (invoice == null) return;
    _elecOldCtrl.text = '${invoice.elecOld}';
    _elecNewCtrl.text = '${invoice.elecNew}';
    _waterOldCtrl.text = '${invoice.waterOld}';
    _waterNewCtrl.text = '${invoice.waterNew}';
  }

  Future<void> _saveMeterReading() async {
    final data = {
      'elecOld': int.tryParse(_elecOldCtrl.text) ?? 0,
      'elecNew': int.tryParse(_elecNewCtrl.text) ?? 0,
      'waterOld': int.tryParse(_waterOldCtrl.text) ?? 0,
      'waterNew': int.tryParse(_waterNewCtrl.text) ?? 0,
    };

    final ok = await context.read<InvoiceProvider>().updateMeterReading(
      widget.invoiceId,
      data,
    );

    if (!mounted) return;
    setState(() => _editingMeters = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Cập nhật chỉ số thành công' : 'Cập nhật chỉ số thất bại',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (ok) {
      await context.read<HostInvoiceListProvider>().refresh();
    }
  }

  Future<void> _confirmPayment() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Xác nhận thanh toán',
      message: 'Xác nhận đã nhận tiền cho hóa đơn này?',
    );
    if (!confirm || !mounted) return;

    final hostId = await context.read<AuthProvider>().getUserId();
    if (!mounted || hostId == null) return;

    final ok = await context.read<InvoiceProvider>().confirmPayment(
      widget.invoiceId,
      hostId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Xác nhận thanh toán thành công' : 'Thao tác thất bại',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (!ok) return;
    await context.read<HostInvoiceListProvider>().refresh();
    if (!mounted) return;
    context.pop();
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2),
                      ),
                    ),
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
                                    invoice.tenantName,
                                    style: AppTextStyles.h3.copyWith(color: fg),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Phòng ${invoice.roomCode}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: subtext,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusBadge(status: invoice.status),
                          ],
                        ),
                        if ((invoice.paymentStatus ?? '').isNotEmpty) ...[
                          const SizedBox(height: 12),
                          PaymentStatusChip(status: invoice.paymentStatus),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          CurrencyUtils.format(invoice.totalAmount),
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.accent,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppDateUtils.formatMonthYear(
                            invoice.billingMonth,
                            invoice.billingYear,
                          ),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết hóa đơn',
                          style: AppTextStyles.body.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _AmountRow(
                          label: 'Tiền phòng',
                          value: CurrencyUtils.format(invoice.rentAmount),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _AmountRow(
                          label:
                              'Tiền điện (${invoice.elecOld} → ${invoice.elecNew} kWh)',
                          value: CurrencyUtils.format(invoice.elecAmount),
                          isDark: isDark,
                        ),
                        if (invoice.elecPrice > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Đơn giá điện: ${CurrencyUtils.format(invoice.elecPrice)}/kWh',
                            style: AppTextStyles.caption.copyWith(
                              color: subtext,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _AmountRow(
                          label:
                              'Tiền nước (${invoice.waterOld} → ${invoice.waterNew} m³)',
                          value: CurrencyUtils.format(invoice.waterAmount),
                          isDark: isDark,
                        ),
                        if (invoice.waterPrice > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Đơn giá nước: ${CurrencyUtils.format(invoice.waterPrice)}/m³',
                            style: AppTextStyles.caption.copyWith(
                              color: subtext,
                            ),
                          ),
                        ],
                        if (invoice.serviceAmount > 0) ...[
                          const SizedBox(height: 8),
                          _AmountRow(
                            label: 'Dịch vụ',
                            value: CurrencyUtils.format(invoice.serviceAmount),
                            isDark: isDark,
                          ),
                        ],
                        if (invoice.dueDate?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 8),
                          _AmountRow(
                            label: 'Hạn thanh toán',
                            value: AppDateUtils.formatDate(invoice.dueDate),
                            isDark: isDark,
                          ),
                        ],
                        Divider(color: border, height: 24),
                        _AmountRow(
                          label: 'Tổng cộng',
                          value: CurrencyUtils.format(invoice.totalAmount),
                          bold: true,
                          color: AppColors.accent,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  if (invoice.hasPaymentProof) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minh chứng chuyển khoản',
                            style: AppTextStyles.body.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (invoice.paymentSubmittedAt?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Người thuê gửi lúc ${AppDateUtils.formatDateTime(invoice.paymentSubmittedAt)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: subtext,
                              ),
                            ),
                          ],
                          if (invoice.paymentNote?.trim().isNotEmpty ?? false) ...[
                            const SizedBox(height: 8),
                            Text(
                              invoice.paymentNote!.trim(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: fg,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Image.network(
                                invoice.paymentProofUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: border,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                        size: 28,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (invoice.status == 'DRAFT' ||
                      invoice.status == 'UNPAID' ||
                      invoice.status == 'OVERDUE') ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Chỉ số điện nước',
                                style: AppTextStyles.body.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              if (!_editingMeters)
                                TextButton(
                                  onPressed: () {
                                    _prefillMeters();
                                    setState(() => _editingMeters = true);
                                  },
                                  child: const Text('Nhập chỉ số'),
                                ),
                            ],
                          ),
                          if (_editingMeters) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Điện cũ (kWh)',
                                    hint: '0',
                                    controller: _elecOldCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Điện mới (kWh)',
                                    hint: '0',
                                    controller: _elecNewCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Nước cũ (m³)',
                                    hint: '0',
                                    controller: _waterOldCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Nước mới (m³)',
                                    hint: '0',
                                    controller: _waterNewCtrl,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Hủy',
                                    variant: AppButtonVariant.outlined,
                                    onPressed: () =>
                                        setState(() => _editingMeters = false),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton(
                                    label: 'Lưu và tính tiền',
                                    onPressed: _saveMeterReading,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (invoice.status == 'UNPAID' ||
                      invoice.status == 'OVERDUE') ...[
                    const SizedBox(height: 16),
                    AppButton(
                      label: invoice.hasPaymentProof
                          ? 'Xác nhận đã nhận chuyển khoản'
                          : 'Xác nhận đã thu tiền',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: _confirmPayment,
                    ),
                  ],
                  if (invoice.status == 'PAID' && invoice.paidAt != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.invoicePaid,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Đã thanh toán lúc ${AppDateUtils.formatDateTime(invoice.paidAt)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.invoicePaid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final bool isDark;

  const _AmountRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 12),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: color ?? fg,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
