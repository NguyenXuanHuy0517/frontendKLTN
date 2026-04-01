import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/issue_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/issue_provider.dart';

class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key});

  @override
  State<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends State<IssueListScreen>
    with SingleTickerProviderStateMixin {
  int? _hostId;
  late TabController _tabCtrl;

  final _tabs = const ['Tất cả', 'Mới', 'Đang xử lý', 'Đã xong'];
  final _statuses = ['', 'OPEN', 'PROCESSING', 'RESOLVED'];

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
      await context.read<IssueProvider>().fetchIssues(_hostId!);
    }
  }

  List<IssueModel> _filtered(List<IssueModel> issues, int tabIndex) {
    final status = _statuses[tabIndex];
    if (status.isEmpty) return issues;
    return issues.where((issue) => issue.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final provider = context.watch<IssueProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Khiếu nại & bảo trì',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: subtext,
          indicatorColor: AppColors.accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.bodySmall,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: provider.loading
          ? const AppLoading()
          : TabBarView(
              controller: _tabCtrl,
              children: List.generate(
                _tabs.length,
                (index) {
                  final issues = _filtered(provider.issues, index);
                  if (issues.isEmpty) {
                    return const AppEmpty(
                      message: 'Không có khiếu nại nào',
                      icon: Icons.report_outlined,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: issues.length,
                      separatorBuilder: (context, separatorIndex) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, itemIndex) => _IssueCard(
                        issue: issues[itemIndex],
                        isDark: isDark,
                      ),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: const HostBottomNav(currentIndex: 4),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final IssueModel issue;
  final bool isDark;

  const _IssueCard({required this.issue, required this.isDark});

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
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final priorityColor = _priorityColor(issue.priority);

    return AppCard(
      featured: issue.priority == 'URGENT' && issue.status == 'OPEN',
      onTap: () => context.push('/host/issues/${issue.issueId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 4),
                    Text(
                      '${issue.tenantName} • Phòng ${issue.roomCode}',
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (issue.hasServiceSuggestion) ...[
            const SizedBox(height: 12),
            _SuggestionChip(label: 'Có đề xuất thêm dịch vụ'),
          ],
          const SizedBox(height: 14),
          Divider(color: border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _priorityLabel(issue.priority),
                  style: AppTextStyles.caption.copyWith(
                    color: priorityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: issue.status),
              const Spacer(),
              Text(
                AppDateUtils.timeAgo(issue.createdAt),
                style: AppTextStyles.caption.copyWith(color: subtext),
              ),
            ],
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
