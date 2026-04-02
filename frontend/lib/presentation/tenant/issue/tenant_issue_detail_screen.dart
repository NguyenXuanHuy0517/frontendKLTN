import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/issue_provider.dart';

class TenantIssueDetailScreen extends StatefulWidget {
  final int issueId;

  const TenantIssueDetailScreen({super.key, required this.issueId});

  @override
  State<TenantIssueDetailScreen> createState() =>
      _TenantIssueDetailScreenState();
}

class _TenantIssueDetailScreenState extends State<TenantIssueDetailScreen> {
  final _feedbackCtrl = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  bool _showRating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (!mounted || userId == null) return;
    await context.read<IssueProvider>().fetchIssueDetailByTenant(
      userId,
      widget.issueId,
    );
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn số sao đánh giá'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final issueProvider = context.read<IssueProvider>();
      final userId = await authProvider.getUserId();
      if (!mounted || userId == null) return;

      await issueProvider.rateIssue(
        issueId: widget.issueId,
        userId: userId,
        rating: _rating,
        feedback: _feedbackCtrl.text.trim().isEmpty
            ? null
            : _feedbackCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đánh giá thành công. Cảm ơn bạn.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      setState(() => _showRating = false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final provider = context.watch<IssueProvider>();
    final issue = provider.selected?.issueId == widget.issueId
        ? provider.selected
        : null;
    final suggestion = issue?.serviceSuggestion;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Chi tiết khiếu nại',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
      ),
      body: provider.loading && issue == null
          ? const AppLoading()
          : issue == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  provider.error ?? 'Không tải được chi tiết khiếu nại.',
                  style: AppTextStyles.body.copyWith(color: subtext),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _priorityColor(
                        issue.priority,
                      ).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _priorityColor(
                          issue.priority,
                        ).withValues(alpha: 0.2),
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
                                style: AppTextStyles.h3.copyWith(color: fg),
                              ),
                            ),
                            StatusBadge(status: issue.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _priorityColor(
                                  issue.priority,
                                ).withValues(alpha: 0.15),
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
                              style: AppTextStyles.caption.copyWith(
                                color: subtext,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (suggestion != null) ...[
                    _ServiceSuggestionCard(
                      serviceName: suggestion.serviceName,
                      note: suggestion.note,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (issue.cleanDescription.isNotEmpty) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mô tả',
                            style: AppTextStyles.body.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            issue.cleanDescription,
                            style: AppTextStyles.body.copyWith(color: subtext),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if ((issue.handlerNote ?? '').trim().isNotEmpty) ...[
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
                                'Phản hồi từ chủ trọ',
                                style: AppTextStyles.body.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              issue.handlerNote!,
                              style: AppTextStyles.body.copyWith(color: fg),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (issue.rating != null) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.warning,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Đánh giá của bạn',
                                style: AppTextStyles.body.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(
                              5,
                              (index) => Icon(
                                index < issue.rating!
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.warning,
                                size: 28,
                              ),
                            ),
                          ),
                          if ((issue.tenantFeedback ?? '')
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              issue.tenantFeedback!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: subtext,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (issue.status == 'RESOLVED' && issue.rating == null) ...[
                    if (!_showRating)
                      AppButton(
                        label: 'Đánh giá kết quả xử lý',
                        icon: Icons.star_outline_rounded,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => setState(() => _showRating = true),
                      )
                    else
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đánh giá kết quả xử lý',
                              style: AppTextStyles.body.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                5,
                                (index) => GestureDetector(
                                  onTap: () =>
                                      setState(() => _rating = index + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Icon(
                                      index < _rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: AppColors.warning,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                _rating == 0
                                    ? 'Chạm để chọn sao'
                                    : const [
                                        '',
                                        'Rất tệ',
                                        'Tệ',
                                        'Bình thường',
                                        'Tốt',
                                        'Rất tốt',
                                      ][_rating],
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _rating == 0
                                      ? subtext
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Nhận xét (tùy chọn)',
                              hint: 'Chia sẻ trải nghiệm của bạn...',
                              controller: _feedbackCtrl,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'Hủy',
                                    variant: AppButtonVariant.outlined,
                                    onPressed: () =>
                                        setState(() => _showRating = false),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton(
                                    label: 'Gửi đánh giá',
                                    onPressed: _submitRating,
                                    loading: _submitting,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiến trình xử lý',
                          style: AppTextStyles.body.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatusStep(
                          label: 'Đã gửi khiếu nại',
                          done: true,
                          active: issue.status == 'OPEN',
                          subtext: subtext,
                        ),
                        _StatusStep(
                          label: 'Đang xử lý',
                          done: issue.status != 'OPEN',
                          active: issue.status == 'PROCESSING',
                          subtext: subtext,
                        ),
                        _StatusStep(
                          label: 'Đã giải quyết',
                          done:
                              issue.status == 'RESOLVED' ||
                              issue.status == 'CLOSED',
                          active: issue.status == 'RESOLVED',
                          subtext: subtext,
                        ),
                        _StatusStep(
                          label: 'Hoàn thành',
                          done: issue.status == 'CLOSED',
                          active: issue.status == 'CLOSED',
                          subtext: subtext,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _ServiceSuggestionCard extends StatelessWidget {
  final String serviceName;
  final String note;

  const _ServiceSuggestionCard({required this.serviceName, required this.note});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      featured: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đề xuất thêm dịch vụ',
                  style: AppTextStyles.body.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            serviceName,
            style: AppTextStyles.body.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (note.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note, style: AppTextStyles.bodySmall.copyWith(color: subtext)),
          ],
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  final Color subtext;
  final bool isLast;

  const _StatusStep({
    required this.label,
    required this.done,
    required this.active,
    required this.subtext,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.success : subtext;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.success
                    : subtext.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.circle_outlined,
                color: done ? Colors.white : subtext,
                size: 14,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: done
                    ? AppColors.success.withValues(alpha: 0.3)
                    : subtext.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: active ? AppColors.success : (done ? color : subtext),
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
