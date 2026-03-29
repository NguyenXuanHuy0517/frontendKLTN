import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/issue_provider.dart';

class IssueDetailScreen extends StatefulWidget {
  final int issueId;
  const IssueDetailScreen({super.key, required this.issueId});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IssueProvider>().fetchIssueDetail(widget.issueId);
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _submitting = true);

    final ok = await context.read<IssueProvider>().updateStatus(
      widget.issueId,
      newStatus,
      _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        Text(ok ? 'Cập nhật trạng thái thành công' : 'Thao tác thất bại'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (ok && newStatus == 'RESOLVED') context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final issue = context.watch<IssueProvider>().selected;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Chi tiết khiếu nại',
            style: AppTextStyles.h3.copyWith(color: fg)),
      ),
      body: issue == null
          ? const AppLoading()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _priorityColor(issue.priority)
                    .withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _priorityColor(issue.priority)
                      .withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          issue.title,
                          style:
                          AppTextStyles.h3.copyWith(color: fg),
                        ),
                      ),
                      StatusBadge(status: issue.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: subtext),
                      const SizedBox(width: 4),
                      Text(
                        '${issue.tenantName} — Phòng ${issue.roomCode}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: subtext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _priorityColor(issue.priority)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _priorityLabel(issue.priority),
                          style: AppTextStyles.caption.copyWith(
                            color: _priorityColor(issue.priority),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppDateUtils.timeAgo(issue.createdAt),
                        style: AppTextStyles.caption
                            .copyWith(color: subtext),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Description ──────────────────────────
            if (issue.description != null &&
                issue.description!.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mô tả',
                      style: AppTextStyles.body.copyWith(
                          color: fg, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      issue.description!,
                      style: AppTextStyles.body
                          .copyWith(color: subtext),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Handler note ─────────────────────────
            if (issue.handlerNote != null &&
                issue.handlerNote!.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: AppColors.accent,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ghi chú xử lý',
                          style: AppTextStyles.body.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      issue.handlerNote!,
                      style: AppTextStyles.body
                          .copyWith(color: subtext),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Rating ───────────────────────────────
            if (issue.rating != null) ...[
              AppCard(
                child: Row(
                  children: [
                    Text(
                      'Đánh giá',
                      style: AppTextStyles.body.copyWith(
                          color: fg, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        5,
                            (i) => Icon(
                          i < issue.rating!
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.warning,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Tenant feedback ──────────────────────
            if (issue.tenantFeedback != null &&
                issue.tenantFeedback!.isNotEmpty) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phản hồi người thuê',
                      style: AppTextStyles.body.copyWith(
                          color: fg, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      issue.tenantFeedback!,
                      style: AppTextStyles.body
                          .copyWith(color: subtext),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Action panel ─────────────────────────
            if (issue.status == 'OPEN' ||
                issue.status == 'PROCESSING') ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xử lý khiếu nại',
                      style: AppTextStyles.body.copyWith(
                          color: fg, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Ghi chú xử lý',
                      hint: 'Nhập ghi chú về cách xử lý...',
                      controller: _noteCtrl,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    if (issue.status == 'OPEN') ...[
                      AppButton(
                        label: 'Bắt đầu xử lý',
                        icon: Icons.build_outlined,
                        variant: AppButtonVariant.outlined,
                        loading: _submitting,
                        onPressed: () =>
                            _updateStatus('PROCESSING'),
                      ),
                      const SizedBox(height: 10),
                    ],

                    AppButton(
                      label: 'Đánh dấu đã giải quyết',
                      icon: Icons.check_circle_outline_rounded,
                      loading: _submitting,
                      onPressed: () => _updateStatus('RESOLVED'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return AppColors.error;
      case 'HIGH':
        return AppColors.warning;
      case 'MEDIUM':
        return AppColors.info;
      default:
        return AppColors.invoiceDraft;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'URGENT':
        return 'Khẩn cấp';
      case 'HIGH':
        return 'Cao';
      case 'MEDIUM':
        return 'Trung bình';
      default:
        return 'Thấp';
    }
  }
}