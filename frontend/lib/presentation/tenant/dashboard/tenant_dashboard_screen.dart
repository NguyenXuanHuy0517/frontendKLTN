import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../data/models/contract_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/contract_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/issue_provider.dart';
import '../../../providers/theme_provider.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  int? _userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _userId = await context.read<AuthProvider>().getUserId();
    if (_userId == null || !mounted) return;
    context.read<ContractProvider>().fetchContractsByTenant(_userId!);
    context.read<InvoiceProvider>().fetchInvoicesByTenant(_userId!);
    context.read<IssueProvider>().fetchIssuesByTenant(_userId!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    final contractProvider = context.watch<ContractProvider>();
    final invoiceProvider = context.watch<InvoiceProvider>();
    final issueProvider = context.watch<IssueProvider>();

    final currentContract = contractProvider.currentContract;
    final unpaidCount = invoiceProvider.unpaidInvoices.length;
    final overdueCount = invoiceProvider.overdueInvoices.length;
    final openIssueCount = issueProvider.openIssues.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: AppColors.gradient),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.home_work_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      GradientText('SmartRoom',
                          style: AppTextStyles.h3,
                          colors: AppColors.gradient),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: subtext,
                          size: 22,
                        ),
                        onPressed: () =>
                            context.read<ThemeProvider>().toggleTheme(),
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined,
                            color: subtext, size: 22),
                        onPressed: () =>
                            context.push('/tenant/notifications'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Greeting ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào,',
                          style:
                          AppTextStyles.body.copyWith(color: subtext)),
                      const SizedBox(height: 4),
                      Text('Trang chủ của bạn',
                          style: AppTextStyles.h1.copyWith(color: fg)),
                    ],
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────
              if (contractProvider.loading)
                const SliverFillRemaining(child: AppLoading())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Current room card
                      _CurrentRoomCard(
                          contract: currentContract, isDark: isDark),
                      const SizedBox(height: 16),

                      // Alert row
                      Row(children: [
                        Expanded(
                          child: _AlertCard(
                            label: 'Chưa thanh toán',
                            count: unpaidCount + overdueCount,
                            icon: Icons.receipt_long_outlined,
                            color: overdueCount > 0
                                ? AppColors.error
                                : AppColors.warning,
                            onTap: () => context.push('/tenant/invoices'),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AlertCard(
                            label: 'Khiếu nại mở',
                            count: openIssueCount,
                            icon: Icons.report_outlined,
                            color: AppColors.warning,
                            onTap: () => context.push('/tenant/issues'),
                            isDark: isDark,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // Quick actions
                      Text('Truy cập nhanh',
                          style: AppTextStyles.h3.copyWith(color: fg)),
                      const SizedBox(height: 12),
                      const _QuickActions(),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 0),
    );
  }
}

// ── Current Room Card ────────────────────────────────────────
class _CurrentRoomCard extends StatelessWidget {
  final ContractModel? contract;
  final bool isDark;

  const _CurrentRoomCard({this.contract, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (contract == null) {
      return AppCard(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: subtext.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.meeting_room_outlined, color: subtext),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chưa có hợp đồng',
                    style: AppTextStyles.body
                        .copyWith(color: fg, fontWeight: FontWeight.w600)),
                Text('Liên hệ chủ trọ để ký hợp đồng',
                    style: AppTextStyles.bodySmall.copyWith(color: subtext)),
              ],
            ),
          ),
        ]),
      );
    }

    // Tính ngày còn lại
    final endDate = DateTime.tryParse(contract!.endDate);
    final daysLeft =
    endDate != null ? endDate.difference(DateTime.now()).inDays : null;
    final expiringSoon = daysLeft != null && daysLeft <= 30 && daysLeft >= 0;

    return AppCard(
      featured: true,
      onTap: () => context.push('/tenant/contract'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.meeting_room_outlined,
                  color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Phòng ${contract!.roomCode}',
                    style: AppTextStyles.h3.copyWith(color: fg),
                  ),
                  Text(
                    contract!.areaName,
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            StatusBadge(status: contract!.status),
          ]),
          const SizedBox(height: 14),
          Divider(color: border, height: 1),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Giá thuê',
                      style: AppTextStyles.caption.copyWith(color: subtext)),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyUtils.format(contract!.actualRentPrice),
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (daysLeft != null) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Kết thúc HĐ',
                        style:
                        AppTextStyles.caption.copyWith(color: subtext)),
                    const SizedBox(height: 2),
                    Text(
                      AppDateUtils.formatDate(contract!.endDate),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: expiringSoon ? AppColors.warning : fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ]),
          if (expiringSoon) ...[
            const SizedBox(height: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Text(
                  'Còn $daysLeft ngày hết hạn — liên hệ chủ trọ để gia hạn',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Alert Card ───────────────────────────────────────────────
class _AlertCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _AlertCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    return AppCard(
      onTap: onTap,
      featured: count > 0,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count',
                  style: AppTextStyles.h3.copyWith(color: fg)),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: subtext),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Quick Actions ────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = [
    _Action(Icons.receipt_long_outlined, 'Hóa đơn', '/tenant/invoices'),
    _Action(Icons.description_outlined, 'Hợp đồng', '/tenant/contract'),
    _Action(Icons.report_outlined, 'Khiếu nại', '/tenant/issues'),
    _Action(Icons.chat_bubble_outline, 'Chatbot', '/tenant/chatbot'),
    _Action(
        Icons.notifications_outlined, 'Thông báo', '/tenant/notifications'),
    _Action(Icons.person_outline_rounded, 'Hồ sơ', '/tenant/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, i) {
        final a = _actions[i];
        return AppCard(
          onTap: () => context.push(a.route),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a.icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                a.label,
                style: AppTextStyles.caption.copyWith(color: fg),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final String route;

  const _Action(this.icon, this.label, this.route);
}