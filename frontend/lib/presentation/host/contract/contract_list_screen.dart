import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/contract_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/contract_provider.dart';

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen>
    with SingleTickerProviderStateMixin {
  int? _hostId;
  late TabController _tabCtrl;
  String _search = '';

  final _tabs = const ['Tất cả', 'Hiệu lực', 'Hết hạn'];
  final _statuses = ['', 'ACTIVE', 'EXPIRED'];

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
      await context.read<ContractProvider>().fetchContracts(_hostId!);
    }
  }

  List<ContractModel> _filtered(List<ContractModel> contracts, int tabIndex) {
    var list = contracts;
    final status = _statuses[tabIndex];
    if (status.isNotEmpty) {
      list = list.where((contract) => contract.status == status).toList();
    }
    if (_search.isNotEmpty) {
      list = list
          .where(
            (contract) =>
                contract.tenantName.toLowerCase().contains(
                  _search.toLowerCase(),
                ) ||
                contract.roomCode.toLowerCase().contains(
                  _search.toLowerCase(),
                ) ||
                contract.contractCode.toLowerCase().contains(
                  _search.toLowerCase(),
                ),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final provider = context.watch<ContractProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Hợp đồng', style: AppTextStyles.h3.copyWith(color: fg)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.accent, size: 26),
            onPressed: () => context.push('/host/contracts/new'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _search = value),
                  style: AppTextStyles.body.copyWith(color: fg),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo người thuê, phòng, mã hợp đồng...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(color: subtext),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: subtext,
                      size: 20,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkCard : AppColors.lightCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ),
              TabBar(
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
            ],
          ),
        ),
      ),
      body: provider.loading
          ? const AppLoading()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: _CreateContractEntryCard(
                    onTap: () => context.push('/host/contracts/new'),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: List.generate(_tabs.length, (index) {
                      final list = _filtered(provider.contracts, index);
                      if (list.isEmpty) {
                        return AppEmpty(
                          message: 'Không có hợp đồng nào',
                          icon: Icons.description_outlined,
                          actionLabel: index == 0 ? 'Tạo hợp đồng mới' : null,
                          onAction: index == 0
                              ? () => context.push('/host/contracts/new')
                              : null,
                        );
                      }
                      return RefreshIndicator(
                        color: AppColors.accent,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: list.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, idx) => _ContractCard(
                            contract: list[idx],
                            isDark: isDark,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const HostBottomNav(currentIndex: 0),
    );
  }
}

class _CreateContractEntryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateContractEntryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      featured: true,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_card_rounded,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo hợp đồng mới',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn phòng trống, nhập điều khoản, sau đó sinh mã thuê cho người thuê.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final ContractModel contract;
  final bool isDark;

  const _ContractCard({required this.contract, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final endDate = DateTime.tryParse(contract.endDate);
    final daysLeft = endDate != null
        ? endDate.difference(DateTime.now()).inDays
        : null;
    final isExpiringSoon = daysLeft != null && daysLeft <= 30 && daysLeft >= 0;

    return AppCard(
      featured: isExpiringSoon,
      onTap: () => context.push('/host/contracts/${contract.contractId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contract.tenantName,
                      style: AppTextStyles.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Phòng ${contract.roomCode} • ${contract.areaName}',
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: contract.status),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: border, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon: Icons.attach_money_rounded,
                  label: CurrencyUtils.format(contract.actualRentPrice),
                  color: AppColors.accent,
                  subtext: subtext,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: AppDateUtils.formatDate(contract.endDate),
                  color: isExpiringSoon ? AppColors.warning : fg,
                  subtext: subtext,
                ),
              ),
            ],
          ),
          if (contract.hasDeposit) ...[
            const SizedBox(height: 10),
            _InfoChip(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Cọc ${CurrencyUtils.format(contract.depositAmount!)}',
              color: AppColors.info,
              subtext: subtext,
            ),
          ],
          if (isExpiringSoon) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Còn $daysLeft ngày hết hạn',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color subtext;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: subtext),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
