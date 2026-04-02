import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_retry_widget.dart';
import '../../../core/widgets/list_search_field.dart';
import '../../../core/widgets/paged_load_more.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../data/models/issue_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/issue_provider.dart';
import '../../../providers/paged_list_state.dart';
import '../../../providers/tenant_issue_list_provider.dart';

class TenantIssueListScreen extends StatefulWidget {
  const TenantIssueListScreen({super.key});

  @override
  State<TenantIssueListScreen> createState() => _TenantIssueListScreenState();
}

class _TenantIssueListScreenState extends State<TenantIssueListScreen> {
  final _searchController = TextEditingController();
  final _statusOptions = const [
    _IssueStatusOption(value: '', label: 'Tat ca'),
    _IssueStatusOption(value: 'OPEN', label: 'Moi'),
    _IssueStatusOption(value: 'PROCESSING', label: 'Dang xu ly'),
    _IssueStatusOption(value: 'RESOLVED', label: 'Da xong'),
    _IssueStatusOption(value: 'CLOSED', label: 'Da dong'),
  ];

  int? _userId;
  Timer? _searchDebounce;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    setState(() => _userId = userId);
    if (userId == null) {
    setState(() {
      _bootstrapError = 'Không xác định được tài khoản người thuê hiện tại.';
    });
    return;
    }

    final provider = context.read<TenantIssueListProvider>();
    _searchController.text = provider.search;
    await provider.bootstrap(userId: userId);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => context.read<TenantIssueListProvider>().applyFilters(search: value),
    );
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
      builder: (_) => _CreateIssueSheet(
        userId: userId,
        onCreated: () => context.read<TenantIssueListProvider>().refresh(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          'Khieu nai & bao tri',
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
      body: _buildBody(isDark),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 2),
    );
  }

  Widget _buildBody(bool isDark) {
    return _TenantIssueBody(
      isDark: isDark,
      bootstrapError: _bootstrapError,
      userId: _userId,
      searchController: _searchController,
      statusOptions: _statusOptions,
      onRetry: _bootstrap,
      onSearchChanged: _onSearchChanged,
      onOpenCreateSheet: _openCreateSheet,
      onOpenIssue: (issue) => context.push('/tenant/issues/${issue.issueId}'),
      onRateIssue: (issue) => context.push('/tenant/issues/${issue.issueId}'),
    );
  }
}

class _TenantIssueBody extends StatelessWidget {
  final bool isDark;
  final String? bootstrapError;
  final int? userId;
  final TextEditingController searchController;
  final List<_IssueStatusOption> statusOptions;
  final Future<void> Function() onRetry;
  final void Function(String value) onSearchChanged;
  final VoidCallback onOpenCreateSheet;
  final void Function(IssueModel issue) onOpenIssue;
  final void Function(IssueModel issue) onRateIssue;

  const _TenantIssueBody({
    required this.isDark,
    required this.bootstrapError,
    required this.userId,
    required this.searchController,
    required this.statusOptions,
    required this.onRetry,
    required this.onSearchChanged,
    required this.onOpenCreateSheet,
    required this.onOpenIssue,
    required this.onRateIssue,
  });

  @override
  Widget build(BuildContext context) {
    if (bootstrapError != null) {
      return ErrorRetryWidget(message: bootstrapError!, onRetry: onRetry);
    }

    final state = context
        .select<TenantIssueListProvider, PagedListState<IssueModel>>(
          (provider) => provider.state,
        );
    final selectedStatus = context.select<TenantIssueListProvider, String>(
      (provider) => provider.status,
    );

    if (state.loading) {
      return const AppLoading();
    }

    if (state.error != null) {
      return ErrorRetryWidget(
        message: state.error!,
        onRetry: () => context.read<TenantIssueListProvider>().refresh(),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<TenantIssueListProvider>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        children: [
          _TenantIssueFiltersSection(
            controller: searchController,
            statusOptions: statusOptions,
            selectedStatus: selectedStatus,
            onSearchChanged: onSearchChanged,
          ),
          _TenantIssueResultsSection(
            state: state,
            isDark: isDark,
            userId: userId,
            onOpenCreateSheet: onOpenCreateSheet,
            onOpenIssue: onOpenIssue,
            onRateIssue: onRateIssue,
          ),
        ],
      ),
    );
  }
}

class _TenantIssueFiltersSection extends StatelessWidget {
  final TextEditingController controller;
  final List<_IssueStatusOption> statusOptions;
  final String selectedStatus;
  final ValueChanged<String> onSearchChanged;

  const _TenantIssueFiltersSection({
    required this.controller,
    required this.statusOptions,
    required this.selectedStatus,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ListSearchField(
            controller: controller,
            hintText: 'Tim theo tieu de khieu nai...',
            onChanged: onSearchChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statusOptions
                .map(
                  (option) => ChoiceChip(
                    label: Text(option.label),
                    selected: selectedStatus == option.value,
                    onSelected: (_) {
                      context.read<TenantIssueListProvider>().applyFilters(
                        status: option.value,
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _TenantIssueResultsSection extends StatelessWidget {
  final PagedListState<IssueModel> state;
  final bool isDark;
  final int? userId;
  final VoidCallback onOpenCreateSheet;
  final void Function(IssueModel issue) onOpenIssue;
  final void Function(IssueModel issue) onRateIssue;

  const _TenantIssueResultsSection({
    required this.state,
    required this.isDark,
    required this.userId,
    required this.onOpenCreateSheet,
    required this.onOpenIssue,
    required this.onRateIssue,
  });

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return AppEmpty(
        message: 'Chua co khieu nai nao',
        icon: Icons.report_outlined,
        actionLabel: 'Gui khieu nai',
        onAction: userId != null ? onOpenCreateSheet : null,
      );
    }

    return Column(
      children: [
        ...state.items.map(
          (issue) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _IssueCard(
              issue: issue,
              isDark: isDark,
              onTap: () => onOpenIssue(issue),
              onRate: issue.status == 'RESOLVED'
                  ? () => onRateIssue(issue)
                  : null,
            ),
          ),
        ),
        if (state.hasNext || state.loadingMore)
          PagedLoadMore(
            loading: state.loadingMore,
            hasNext: state.hasNext,
            onPressed: () => context.read<TenantIssueListProvider>().loadMore(),
          ),
      ],
    );
  }
}

class _IssueStatusOption {
  final String value;
  final String label;

  const _IssueStatusOption({required this.value, required this.label});
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
              _SuggestionChip(label: 'Co de xuat them dich vu'),
            ],
            Divider(color: border, height: 20),
            Row(
              children: [
                StatusBadge(status: issue.status),
                const Spacer(),
                if (issue.status == 'RESOLVED')
                  TextButton(onPressed: onRate, child: const Text('Danh gia')),
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

  const _CreateIssueSheet({required this.userId, required this.onCreated});

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
        ? 'De xuat them dich vu'
        : '';
    final title = _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : fallbackTitle;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui long nhap tieu de khieu nai'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_includeServiceSuggestion && _serviceNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nhap ten dich vu ma ban muon de xuat'),
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
        issueType: _includeServiceSuggestion ? 'SERVICE_SUGGESTION' : 'GENERAL',
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
                ? 'Da gui khieu nai kem de xuat dich vu'
                : 'Gui khieu nai thanh cong',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi: $error'),
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
          Text('Gui khieu nai', style: AppTextStyles.h3.copyWith(color: fg)),
          const SizedBox(height: 20),
          AppTextField(
            label: 'Tieu de',
            hint: 'VD: Quat phong bi hong',
            controller: _titleCtrl,
            prefixIcon: Icons.title,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Mo ta chi tiet',
            hint: 'Mo ta van de dang gap...',
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
                'De xuat them dich vu',
                style: AppTextStyles.body.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Bat muc nay neu ban muon gop y chu tro bo sung dich vu moi.',
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
              hint: 'Nếu lợi ích hoặc nhu cầu thực tế của bạn...',
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
            label: 'Gui khieu nai',
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
