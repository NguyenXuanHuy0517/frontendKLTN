import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/admin_host_model.dart';
import '../../../providers/admin_host_provider.dart';
import '../widgets/admin_host_status_dialog.dart';
import '../widgets/admin_shell.dart';

class AdminHostDetailScreen extends StatefulWidget {
  final int hostId;

  const AdminHostDetailScreen({super.key, required this.hostId});

  @override
  State<AdminHostDetailScreen> createState() => _AdminHostDetailScreenState();
}

class _AdminHostDetailScreenState extends State<AdminHostDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await context.read<AdminHostProvider>().fetchHostDetail(widget.hostId);
  }

  Future<void> _changeStatus(AdminHostModel host) async {
    final activating = !host.isActive;
    final result = await AdminHostStatusDialog.show(
      context,
      hostName: host.fullName,
      activating: activating,
    );
    if (!mounted || result == null) return;

    final ok = await context.read<AdminHostProvider>().updateHostStatus(
          widget.hostId,
          active: activating,
          reason: result.reason,
          note: result.note,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (activating
                  ? 'Da mo khoa host thanh cong'
                  : 'Da khoa host thanh cong')
              : 'Khong cap nhat duoc trang thai host',
        ),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminHostProvider>();
    final host = provider.selected;

    return AdminShell(
      currentIndex: 1,
      title: 'Host Detail',
      subtitle: 'Snapshot van hanh va trang thai host',
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Tai lai',
        ),
      ],
      child: provider.detailLoading && host == null
          ? const AppLoading()
          : provider.error != null && host == null
              ? AppEmpty(
                  message: provider.error!,
                  icon: Icons.person_off_outlined,
                  actionLabel: 'Thu lai',
                  onAction: _load,
                )
              : host == null
                  ? const AppEmpty(message: 'Khong co du lieu host.')
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.accent,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _HostHeroCard(
                            host: host,
                            loading: provider.statusUpdating,
                            onToggle: () => _changeStatus(host),
                          ),
                          const SizedBox(height: 20),
                          _HostMetricGrid(host: host),
                          const SizedBox(height: 20),
                          _HostContextPanel(host: host),
                        ],
                      ),
                    ),
    );
  }
}

class _HostHeroCard extends StatelessWidget {
  final AdminHostModel host;
  final bool loading;
  final VoidCallback onToggle;

  const _HostHeroCard({
    required this.host,
    required this.loading,
    required this.onToggle,
  });

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(host.fullName, style: AppTextStyles.h2.copyWith(color: fg)),
                    const SizedBox(height: 4),
                    Text(host.email, style: AppTextStyles.body.copyWith(color: subtext)),
                    const SizedBox(height: 4),
                    Text(
                      host.phoneNumber.isEmpty
                          ? 'Chua cap nhat so dien thoai'
                          : host.phoneNumber,
                      style: AppTextStyles.body2.copyWith(color: subtext),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: loading ? null : onToggle,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      host.isActive ? AppColors.error : AppColors.success,
                ),
                icon: Icon(
                  host.isActive
                      ? Icons.lock_outline_rounded
                      : Icons.lock_open_rounded,
                ),
                label: Text(host.isActive ? 'Khoa host' : 'Mo khoa'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _StateBadge(
                label: host.isActive ? 'Dang hoat dong' : 'Da khoa',
                color: host.isActive ? AppColors.success : AppColors.error,
              ),
              if (host.warningCount > 0) ...[
                const SizedBox(width: 10),
                _StateBadge(
                  label: '${host.warningCount} canh bao',
                  color: AppColors.warning,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HostMetricGrid extends StatelessWidget {
  final AdminHostModel host;

  const _HostMetricGrid({required this.host});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Tong areas', '${host.totalAreas}'),
      ('Tong rooms', '${host.totalRooms}'),
      ('Active contracts', '${host.activeContracts}'),
      ('Overdue invoices', '${host.overdueInvoices}'),
      ('Rooms no invoice', '${host.roomsWithoutInvoice}'),
      ('Warnings', '${host.warningCount}'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 3 : width >= 640 ? 2 : 1;
        final itemWidth = (width - (columns - 1) * 16) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: AppTextStyles.caption),
                        const SizedBox(height: 8),
                        Text(item.$2, style: AppTextStyles.h2),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _HostContextPanel extends StatelessWidget {
  final AdminHostModel host;

  const _HostContextPanel({required this.host});

  @override
  Widget build(BuildContext context) {
    final subtext = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSubtext
        : AppColors.lightSubtext;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Admin notes', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Ly do trang thai gan nhat',
            value: host.latestStatusReason.isEmpty
                ? 'Chua co ly do duoc luu tu backend'
                : host.latestStatusReason,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Ghi chu',
            value: host.note.isEmpty ? 'Khong co ghi chu them' : host.note,
          ),
          const SizedBox(height: 12),
          Text(
            'Trang nay chi de giam sat va khoa/mo host. Khong thuc hien CRUD nghiep vu tu day.',
            style: AppTextStyles.body2.copyWith(color: subtext),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final subtext = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSubtext
        : AppColors.lightSubtext;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: subtext)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.body),
      ],
    );
  }
}

class _StateBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StateBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
