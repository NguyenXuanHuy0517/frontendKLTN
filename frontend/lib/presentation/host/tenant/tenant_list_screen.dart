import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/tenant_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tenant_provider.dart';

class TenantListScreen extends StatefulWidget {
  const TenantListScreen({super.key});

  @override
  State<TenantListScreen> createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  int? _hostId;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _hostId = await context.read<AuthProvider>().getUserId();
    if (_hostId != null && mounted) {
      context.read<TenantProvider>().fetchTenants(_hostId!);
    }
  }

  List<TenantModel> _filtered(List<TenantModel> tenants) {
    if (_search.isEmpty) return tenants;
    return tenants
        .where((t) =>
    t.fullName.toLowerCase().contains(_search.toLowerCase()) ||
        t.phoneNumber.contains(_search) ||
        t.email.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final provider = context.watch<TenantProvider>();
    final list = _filtered(provider.tenants);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Người thuê', style: AppTextStyles.h3.copyWith(color: fg)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.accent, size: 26),
            onPressed: () => context.push('/host/tenants/new'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: AppTextStyles.body.copyWith(color: fg),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT, email...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: subtext),
                prefixIcon:
                Icon(Icons.search_rounded, color: subtext, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
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
        ),
      ),
      body: provider.loading
          ? const AppLoading()
          : list.isEmpty
          ? AppEmpty(
        message: _search.isEmpty
            ? 'Chưa có người thuê nào'
            : 'Không tìm thấy kết quả',
        icon: Icons.people_outline_rounded,
        actionLabel: _search.isEmpty ? 'Thêm người thuê' : null,
        onAction: _search.isEmpty
            ? () => context.push('/host/tenants/new')
            : null,
      )
          : RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _TenantCard(tenant: list[i], isDark: isDark),
        ),
      ),
      bottomNavigationBar: const HostBottomNav(currentIndex: 0),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final TenantModel tenant;
  final bool isDark;
  const _TenantCard({required this.tenant, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      onTap: () => context.push('/host/tenants/${tenant.userId}'),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: tenant.active
                  ? AppColors.accent.withOpacity(0.1)
                  : AppColors.darkSubtext.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                tenant.fullName.isNotEmpty
                    ? tenant.fullName[0].toUpperCase()
                    : '?',
                style: AppTextStyles.h3.copyWith(
                  color: tenant.active
                      ? AppColors.accent
                      : AppColors.darkSubtext,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tenant.fullName,
                        style: AppTextStyles.body.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                        status: tenant.active ? 'ACTIVE' : 'EXPIRED'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tenant.phoneNumber,
                  style: AppTextStyles.bodySmall.copyWith(color: subtext),
                ),
                if (tenant.currentRoomCode != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.meeting_room_outlined,
                          size: 13, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Phòng ${tenant.currentRoomCode}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Icon(Icons.chevron_right_rounded, color: subtext, size: 20),
        ],
      ),
    );
  }
}