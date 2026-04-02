import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/error_retry_widget.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/list_search_field.dart';
import '../../../core/widgets/paged_load_more.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/issue_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/host_issue_list_provider.dart';

class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key});

  @override
  State<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends State<IssueListScreen>
    with SingleTickerProviderStateMixin {
  final _tabs = const ['Tất cả', 'Mới', 'Đang xử lý', 'Đã xong'];
  final _statuses = const ['', 'OPEN', 'PROCESSING', 'RESOLVED'];
  final _issueTypeOptions = const [
    _IssueTypeOption(value: '', label: 'Tất cả'),
    _IssueTypeOption(value: 'GENERAL', label: 'Khiếu nại chung'),
    _IssueTypeOption(value: 'SERVICE_SUGGESTION', label: 'Đề xuất dịch vụ'),
  ];
  final _searchController = TextEditingController();

  late final TabController _tabCtrl;

  int? _hostId;
  Timer? _searchDebounce;
  String? _bootstrapError;

  String get _currentStatus => _statuses[_tabCtrl.index];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(_handleTabChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tabCtrl
      ..removeListener(_handleTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final hostId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    if (hostId == null) {
      setState(() {
        _bootstrapError = 'Khong xac dinh duoc tai khoan chu tro hien tai.';
      });
      return;
    }

    _hostId = hostId;
    final provider = context.read<HostIssueListProvider>();
    final initialTab = _statuses.indexOf(provider.status);
    if (initialTab >= 0 && _tabCtrl.index != initialTab) {
      _tabCtrl.index = initialTab;
    }
    _searchController.text = provider.search;
    await provider.bootstrap(hostId: hostId);
  }

  void _handleTabChanged() {
    if (_tabCtrl.indexIsChanging || _hostId == null) return;
    context.read<HostIssueListProvider>().applyFilters(status: _currentStatus);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => context.read<HostIssueListProvider>().applyFilters(search: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Khieu nai & bao tri',
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
      body: _buildBody(isDark),
      bottomNavigationBar: const HostBottomNav(currentIndex: 4),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_bootstrapError != null) {
      return ErrorRetryWidget(message: _bootstrapError!, onRetry: _bootstrap);
    }

    final provider = context.watch<HostIssueListProvider>();
    final state = provider.state;

    if (state.loading) {
      return const AppLoading();
    }

    if (state.error != null) {
      return ErrorRetryWidget(
        message: state.error!,
        onRetry: () => context.read<HostIssueListProvider>().refresh(),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<HostIssueListProvider>().refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        itemCount:
            2 +
            (state.items.isEmpty ? 1 : state.items.length) +
            ((state.hasNext || state.loadingMore) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListSearchField(
                controller: _searchController,
                hintText: 'Tim theo tieu de, nguoi thue, phong...',
                onChanged: _onSearchChanged,
              ),
            );
          }

          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _issueTypeOptions
                    .map(
                      (option) => ChoiceChip(
                        label: Text(option.label),
                        selected: provider.issueType == option.value,
                        onSelected: (_) {
                          context.read<HostIssueListProvider>().applyFilters(
                            issueType: option.value,
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            );
          }

          if (state.items.isEmpty) {
            return const AppEmpty(
              message: 'Khong co khieu nai nao',
              icon: Icons.report_outlined,
            );
          }

          final itemIndex = index - 2;
          if (itemIndex == state.items.length) {
            return PagedLoadMore(
              loading: state.loadingMore,
              hasNext: state.hasNext,
              onPressed: () => context.read<HostIssueListProvider>().loadMore(),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _IssueCard(issue: state.items[itemIndex], isDark: isDark),
          );
        },
      ),
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
        return 'Khan cap';
      case 'HIGH':
        return 'Cao';
      case 'MEDIUM':
        return 'Trung binh';
      default:
        return 'Thap';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final priorityColor = _priorityColor(issue.priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/host/issues/${issue.issueId}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
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
                          '${issue.tenantName} - Phong ${issue.roomCode}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (issue.hasServiceSuggestion) ...[
                const SizedBox(height: 12),
                _SuggestionChip(label: 'Co de xuat them dich vu'),
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
        ),
      ),
    );
  }
}

class _IssueTypeOption {
  final String value;
  final String label;

  const _IssueTypeOption({required this.value, required this.label});
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
