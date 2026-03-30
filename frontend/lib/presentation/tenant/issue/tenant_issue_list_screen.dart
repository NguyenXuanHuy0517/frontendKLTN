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
import '../../../data/models/issue_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/issue_provider.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';

class TenantIssueListScreen extends StatefulWidget {
  const TenantIssueListScreen({super.key});
  @override
  State<TenantIssueListScreen> createState() => _TenantIssueListScreenState();
}

class _TenantIssueListScreenState extends State<TenantIssueListScreen> {
  int? _userId;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    _userId = await context.read<AuthProvider>().getUserId();
    if (_userId != null && mounted) {
      context.read<IssueProvider>().fetchIssuesByTenant(_userId!);
    }
  }

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateIssueSheet(
        userId: _userId!,
        onCreated: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg       = isDark ? AppColors.darkFg : AppColors.lightFg;
    final provider = context.watch<IssueProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Khiếu nại & Bảo trì',
            style: AppTextStyles.h3.copyWith(color: fg)),
        actions: [
          if (_userId != null)
            IconButton(
              icon: const Icon(Icons.add_rounded,
                  color: AppColors.accent, size: 26),
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
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _IssueCard(
              issue: provider.issues[i], isDark: isDark),
        ),
      ),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 2),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final IssueModel issue;
  final bool isDark;
  const _IssueCard({required this.issue, required this.isDark});

  Color _priorityColor() {
    switch (issue.priority) {
      case 'URGENT': return AppColors.error;
      case 'HIGH':   return AppColors.warning;
      case 'MEDIUM': return AppColors.info;
      default:       return AppColors.invoiceDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg      = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border  = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final pc      = _priorityColor();

    return AppCard(
      featured: issue.status == 'OPEN' && issue.priority == 'URGENT',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: pc.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.report_problem_outlined, color: pc, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(issue.title,
                  style: AppTextStyles.body
                      .copyWith(color: fg, fontWeight: FontWeight.w600),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(AppDateUtils.timeAgo(issue.createdAt),
                  style: AppTextStyles.caption.copyWith(color: subtext)),
            ],
          )),
        ]),
        Divider(color: border, height: 20),
        Row(children: [
          StatusBadge(status: issue.status),
          const Spacer(),
          if (issue.status == 'RESOLVED')
            TextButton(
              onPressed: () {},  // TODO: open rating dialog
              child: const Text('Đánh giá'),
            ),
        ]),
      ]),
    );
  }
}

// ── Create issue bottom sheet ────────────────────────────────
class _CreateIssueSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onCreated;
  const _CreateIssueSheet({required this.userId, required this.onCreated});
  @override
  State<_CreateIssueSheet> createState() => _CreateIssueSheetState();
}

class _CreateIssueSheetState extends State<_CreateIssueSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _priority = 'MEDIUM';
  bool _loading    = false;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await context.read<IssueProvider>().createIssueByTenant(
        userId: widget.userId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        priority: _priority,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gửi khiếu nại thành công'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? AppColors.darkCard : AppColors.lightCard;
    final fg       = isDark ? AppColors.darkFg : AppColors.lightFg;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Gửi khiếu nại',
            style: AppTextStyles.h3.copyWith(color: fg)),
        const SizedBox(height: 20),
        AppTextField(
          label: 'Tiêu đề *',
          hint: 'VD: Quạt phòng bị hỏng',
          controller: _titleCtrl,
          prefixIcon: Icons.title,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'Mô tả chi tiết',
          hint: 'Mô tả vấn đề...',
          controller: _descCtrl,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        // Priority selector
        Row(children: [
          Text('Mức độ ưu tiên: ',
              style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
          const SizedBox(width: 8),
          ...[
            ('LOW', 'Thấp', AppColors.invoiceDraft),
            ('MEDIUM', 'TB', AppColors.info),
            ('HIGH', 'Cao', AppColors.warning),
            ('URGENT', 'Khẩn', AppColors.error),
          ].map((e) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(e.$2,
                  style: AppTextStyles.caption
                      .copyWith(color: _priority == e.$1
                      ? Colors.white : e.$3)),
              selected: _priority == e.$1,
              selectedColor: e.$3,
              backgroundColor: e.$3.withOpacity(0.1),
              onSelected: (_) => setState(() => _priority = e.$1),
            ),
          )),
        ]),
        const SizedBox(height: 20),
        AppButton(
          label: 'Gửi khiếu nại',
          onPressed: _submit,
          loading: _loading,
        ),
      ]),
    );
  }
}