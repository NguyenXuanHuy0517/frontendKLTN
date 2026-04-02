import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_popup_window.dart';
import '../../../core/widgets/payment_status_chip.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/tenant_invoice_list_provider.dart';

class TenantInvoiceDetailScreen extends StatefulWidget {
  final int invoiceId;

  const TenantInvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<TenantInvoiceDetailScreen> createState() =>
      _TenantInvoiceDetailScreenState();
}

class _TenantInvoiceDetailScreenState extends State<TenantInvoiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = await context.read<AuthProvider>().getUserId();
      if (!mounted || userId == null) return;
      await context.read<InvoiceProvider>().fetchInvoiceDetailByTenant(
        widget.invoiceId,
        userId,
      );
    });
  }

  Future<void> _openPaymentPopup(InvoiceDetailModel invoice) async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (!mounted || userId == null) return;

    final submitted = await AppPopupWindow.show<bool>(
      context,
      maxWidth: 720,
      maxHeight: 820,
      child: _PaymentProofPopup(invoice: invoice, userId: userId),
    );

    if (!mounted || submitted != true) return;
    await context.read<TenantInvoiceListProvider>().refresh();
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
                      color: AppColors.accent.withValues(alpha: 0.06),
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
                                    AppDateUtils.formatMonthYear(
                                      invoice.billingMonth,
                                      invoice.billingYear,
                                    ),
                                    style: AppTextStyles.h3.copyWith(color: fg),
                                  ),
                                  if (invoice.roomCode.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Phòng ${invoice.roomCode}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: subtext,
                                      ),
                                    ),
                                  ],
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
                        const SizedBox(height: 12),
                        Text(
                          CurrencyUtils.format(invoice.totalAmount),
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.accent,
                            fontSize: 28,
                          ),
                        ),
                        if (invoice.status == 'UNPAID' ||
                            invoice.status == 'OVERDUE') ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: invoice.status == 'OVERDUE'
                                    ? AppColors.error
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  invoice.status == 'OVERDUE'
                                      ? 'Hóa đơn đã quá hạn thanh toán.'
                                      : 'Vui lòng thanh toán đúng hạn và gửi minh chứng chuyển khoản.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: invoice.status == 'OVERDUE'
                                        ? AppColors.error
                                        : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết thanh toán',
                          style: AppTextStyles.body.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
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
                              'Tiền điện (${invoice.elecOld} → ${invoice.elecNew} kWh)',
                          value: CurrencyUtils.format(invoice.elecAmount),
                          fg: fg,
                          subtext: subtext,
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
                        _DetailRow(
                          label:
                              'Tiền nước (${invoice.waterOld} → ${invoice.waterNew} m³)',
                          value: CurrencyUtils.format(invoice.waterAmount),
                          fg: fg,
                          subtext: subtext,
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
                          _DetailRow(
                            label: 'Dịch vụ',
                            value: CurrencyUtils.format(invoice.serviceAmount),
                            fg: fg,
                            subtext: subtext,
                          ),
                          if (invoice.serviceNames.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: invoice.serviceNames
                                  .map(
                                    (serviceName) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        serviceName,
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                        Divider(color: border, height: 24),
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
                  if (invoice.dueDate?.isNotEmpty ?? false &&
                      (invoice.status == 'UNPAID' ||
                          invoice.status == 'OVERDUE')) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: invoice.status == 'OVERDUE'
                                ? AppColors.error
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hạn thanh toán',
                                style: AppTextStyles.caption.copyWith(
                                  color: subtext,
                                ),
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
                        ],
                      ),
                    ),
                  ],
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
                              'Đã gửi lúc ${AppDateUtils.formatDateTime(invoice.paymentSubmittedAt)}',
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
                          _ProofImage(url: invoice.paymentProofUrl!),
                        ],
                      ),
                    ),
                  ],
                  if (invoice.status != 'PAID') ...[
                    const SizedBox(height: 20),
                    AppButton(
                      label: invoice.hasPaymentProof
                          ? 'Cập nhật minh chứng thanh toán'
                          : 'Thanh toán',
                      icon: invoice.hasPaymentProof
                          ? Icons.edit_outlined
                          : Icons.qr_code_rounded,
                      onPressed: () => _openPaymentPopup(invoice),
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
                          Expanded(
                            child: Text(
                              'Đã thanh toán lúc ${AppDateUtils.formatDateTime(invoice.paidAt)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.invoicePaid,
                              ),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;
  final Color subtext;
  final bool bold;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.fg,
    required this.subtext,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
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
            color: fg,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProofImage extends StatelessWidget {
  final String url;

  const _ProofImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.lightBorder,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image_outlined, size: 28),
          ),
        ),
      ),
    );
  }
}

class _PaymentProofPopup extends StatefulWidget {
  final InvoiceDetailModel invoice;
  final int userId;

  const _PaymentProofPopup({
    required this.invoice,
    required this.userId,
  });

  @override
  State<_PaymentProofPopup> createState() => _PaymentProofPopupState();
}

class _PaymentProofPopupState extends State<_PaymentProofPopup> {
  final _picker = ImagePicker();
  final _noteController = TextEditingController();

  Uint8List? _previewBytes;
  XFile? _selectedFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.invoice.paymentNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickProofImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedFile = picked;
      _previewBytes = bytes;
    });
  }

  Future<void> _submit() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ảnh minh chứng chuyển khoản.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final ok = await context.read<InvoiceProvider>().submitPaymentProof(
      invoiceId: widget.invoice.invoiceId,
      userId: widget.userId,
      file: _selectedFile!,
      note: _noteController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi minh chứng thanh toán thất bại.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã gửi minh chứng thanh toán, vui lòng chờ chủ trọ xác nhận.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fillColor = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        automaticallyImplyLeading: false,
        title: Text(
          'Thanh toán hóa đơn',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(false),
            icon: Icon(Icons.close_rounded, color: fg),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.invoice.invoiceCode,
                    style: AppTextStyles.body.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tổng tiền: ${CurrencyUtils.format(widget.invoice.totalAmount)}',
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nội dung chuyển khoản: ${widget.invoice.invoiceCode}',
                    style: AppTextStyles.bodySmall.copyWith(color: fg),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Mã QR thanh toán',
                    style: AppTextStyles.body.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR hiển thị mã hóa đơn và thông tin tham chiếu để bạn đối chiếu khi chuyển khoản.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: QrImageView(
                      data: _buildQrPayload(widget.invoice),
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ảnh xác nhận chuyển khoản',
              style: AppTextStyles.body.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickProofImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.24),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _previewBytes == null
                    ? Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 34,
                            color: AppColors.accent,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Chọn ảnh minh chứng',
                            style: AppTextStyles.body.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ảnh biên lai, ảnh chụp màn hình giao dịch hoặc xác nhận ngân hàng.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: subtext,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _previewBytes!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ghi chú',
              style: AppTextStyles.body.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 4,
              style: AppTextStyles.body.copyWith(color: fg),
              decoration: InputDecoration(
                hintText: 'Ví dụ: đã chuyển khoản từ tài khoản MB Bank lúc 19:35.',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: subtext),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Đóng',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Đã chuyển khoản',
                    icon: Icons.check_circle_outline_rounded,
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildQrPayload(InvoiceDetailModel invoice) {
    return [
      'SMARTROOMMS',
      'invoice=${invoice.invoiceCode}',
      'room=${invoice.roomCode}',
      'amount=${invoice.totalAmount.toStringAsFixed(0)}',
      'due=${invoice.dueDate ?? ''}',
    ].join('|');
  }
}
