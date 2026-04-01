import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../data/models/issue_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/issue_provider.dart';

class TenantIssueListScreen extends StatefulWidget {
  const TenantIssueListScreen({super.key});

  @override
  State<TenantIssueListScreen> createState() => _TenantIssueListScreenState();
}

class _TenantIssueListScreenState extends State<TenantIssueListScreen> {
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    setState(() => _userId = userId);
    if (userId != null) {
      await context.read<IssueProvider>().fetchIssuesByTenant(userId);
    }
  }

  void _openCreateSheet() {
    final userId = _userId;
    if (userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateIssueSheet(userId: userId, onCreated: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final provider = context.watch<IssueProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          'Khiếu nại & bảo trì',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          if (_userId != null)
            IconButton(
              icon: const Icon(
                Icons.add_rounded,
                color: AppColors.accent,
                size: 26,
              ),
              onPressed: _openCreateSheet,
            ),
        ],
      ),
      body: provider.loading
          ? const AppLoading()
          : provider.issues.isEmpty
              ? AppEmpty(
                  message: 'Chưa có khiếu nại nào',
                  icon: Icons.report_outlined,
                  actionLabel: 'Gửi khiếu nại',
                  onAction: _userId != null ? _openCreateSheet : null,
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: provider.issues.length,
                    separatorBuilder: (context, separatorIndex) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final issue = provider.issues[index];
                      return _IssueCard(
                        issue: issue,
                        isDark: isDark,
                        onTap: () => context.push('/tenant/issues/${issue.issueId}'),
                        onRate: issue.status == 'RESOLVED'
                            ? () => context.push('/tenant/issues/${issue.issueId}')
                            : null,
                      );
                    },
                  ),
                ),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 2),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final IssueModel issue;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onRate;

  const _IssueCard({
    required this.issue,
    required this.isDark,
    required this.onTap,
    this.onRate,
  });

  Color _priorityColor() {
    switch (issue.priority) {
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

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final priorityColor = _priorityColor();

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        featured: issue.status == 'OPEN' && issue.priority == 'URGENT',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.report_problem_outlined,
                    color: priorityColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: AppTextStyles.body.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppDateUtils.timeAgo(issue.createdAt),
                        style: AppTextStyles.caption.copyWith(color: subtext),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: subtext),
              ],
            ),
            if (issue.hasServiceSuggestion) ...[
              const SizedBox(height: 12),
              _SuggestionChip(label: 'Có đề xuất thêm dịch vụ'),
            ],
            Divider(color: border, height: 20),
            Row(
              children: [
                StatusBadge(status: issue.status),
                const Spacer(),
                if (issue.status == 'RESOLVED')
                  TextButton(
                    onPressed: onRate,
                    child: const Text('Đánh giá'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateIssueSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onCreated;

  const _CreateIssueSheet({
    required this.userId,
    required this.onCreated,
  });

  @override
  State<_CreateIssueSheet> createState() => _CreateIssueSheetState();
}

class _CreateIssueSheetState extends State<_CreateIssueSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _serviceNameCtrl = TextEditingController();
  final _serviceNoteCtrl = TextEditingController();
  String _priority = 'MEDIUM';
  bool _loading = false;
  bool _includeServiceSuggestion = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _serviceNameCtrl.dispose();
    _serviceNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final fallbackTitle = _includeServiceSuggestion
        ? 'Đề xuất thêm dịch vụ'
        : '';
    final title = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : fallbackTitle;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tiêu đề khiếu nại'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_includeServiceSuggestion &&
        _serviceNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhập tên dịch vụ mà bạn muốn đề xuất'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<IssueProvider>().createIssueByTenant(
            userId: widget.userId,
            title: title,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            priority: _priority,
            issueType:
                _includeServiceSuggestion ? 'SERVICE_SUGGESTION' : 'GENERAL',
            suggestedServiceName: _includeServiceSuggestion
                ? _serviceNameCtrl.text.trim()
                : null,
            suggestionNote: _includeServiceSuggestion
                ? _serviceNoteCtrl.text.trim()
                : null,
          );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _includeServiceSuggestion
                ? 'Đã gửi khiếu nại kèm đề xuất dịch vụ'
                : 'Gửi khiếu nại thành công',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
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
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Gửi khiếu nại',
            style: AppTextStyles.h3.copyWith(color: fg),
          ),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Tiêu đề',
            hint: 'VD: Quạt phòng bị hỏng',
            controller: _titleCtrl,
            prefixIcon: Icons.title,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Mô tả chi tiết',
            hint: 'Mô tả vấn đề đang gặp...',
            controller: _descCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
            child: SwitchListTile.adaptive(
              title: Text(
                'Đề xuất thêm dịch vụ',
                style: AppTextStyles.body.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Bật mục này nếu bạn muốn góp ý chủ trọ bổ sung dịch vụ mới.',
                style: AppTextStyles.bodySmall.copyWith(color: subtext),
              ),
              value: _includeServiceSuggestion,
              activeTrackColor: AppColors.accent.withValues(alpha: 0.35),
              activeThumbColor: AppColors.accent,
              onChanged: (value) {
                setState(() => _includeServiceSuggestion = value);
              },
            ),
          ),
          if (_includeServiceSuggestion) ...[
            const SizedBox(height: 12),
            AppTextField(
              label: 'Tên dịch vụ đề xuất',
              hint: 'VD: Giặt sấy, Internet tốc độ cao...',
              controller: _serviceNameCtrl,
              prefixIcon: Icons.miscellaneous_services_outlined,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Lý do đề xuất',
              hint: 'Nêu lợi ích hoặc nhu cầu thực tế của bạn...',
              controller: _serviceNoteCtrl,
              maxLines: 3,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Mức độ ưu tiên:',
                style: AppTextStyles.label.copyWith(color: subtext),
              ),
              const SizedBox(width: 8),
              ...[
                ('LOW', 'Thấp', AppColors.invoiceDraft),
                ('MEDIUM', 'TB', AppColors.info),
                ('HIGH', 'Cao', AppColors.warning),
                ('URGENT', 'Khẩn', AppColors.error),
              ].map(
                (item) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      item.$2,
                      style: AppTextStyles.caption.copyWith(
                        color: _priority == item.$1 ? Colors.white : item.$3,
                      ),
                    ),
                    selected: _priority == item.$1,
                    selectedColor: item.$3,
                    backgroundColor: item.$3.withValues(alpha: 0.1),
                    onSelected: (_) => setState(() => _priority = item.$1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Gửi khiếu nại',
            onPressed: _submit,
            loading: _loading,
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;

  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
