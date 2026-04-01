import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/admin_host_model.dart';
import '../../../providers/admin_host_provider.dart';
import '../widgets/admin_shell.dart';

class AdminHostListScreen extends StatefulWidget {
  const AdminHostListScreen({super.key});

  @override
  State<AdminHostListScreen> createState() => _AdminHostListScreenState();
}

class _AdminHostListScreenState extends State<AdminHostListScreen> {
  String _search = '';
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await context.read<AdminHostProvider>().fetchHosts();
  }

  List<AdminHostModel> _filtered(List<AdminHostModel> input) {
    var items = input;
    if (_status == 'active') {
      items = items.where((item) => item.isActive).toList();
    } else if (_status == 'inactive') {
      items = items.where((item) => !item.isActive).toList();
    }
    if (_search.isNotEmpty) {
      final keyword = _search.toLowerCase();
      items = items.where((item) {
        return item.fullName.toLowerCase().contains(keyword) ||
            item.email.toLowerCase().contains(keyword) ||
            item.phoneNumber.toLowerCase().contains(keyword);
      }).toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminHostProvider>();
    final hosts = _filtered(provider.hosts);
    final isWide = MediaQuery.of(context).size.width >= 1024;

    return AdminShell(
      currentIndex: 1,
      title: 'Host Management',
      subtitle: 'Ra soat, tim kiem va cap nhat trang thai host',
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Tai lai',
        ),
      ],
      child: provider.loading && provider.hosts.isEmpty
          ? const AppLoading()
          : provider.error != null && provider.hosts.isEmpty
              ? AppEmpty(
                  message: provider.error!,
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Thu lai',
                  onAction: _load,
                )
              : Column(
                  children: [
                    _HostFilterBar(
                      status: _status,
                      onSearchChanged: (value) =>
                          setState(() => _search = value),
                      onStatusChanged: (value) =>
                          setState(() => _status = value),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.accent,
                        child: hosts.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  AppEmpty(
                                    message: 'Khong co host phu hop bo loc.',
                                    icon: Icons.filter_alt_off_outlined,
                                  ),
                                ],
                              )
                            : isWide
                                ? _HostTable(hosts: hosts)
                                : ListView.separated(
                                    padding: const EdgeInsets.all(24),
                                    itemCount: hosts.length,
                                    separatorBuilder: (_, separatorIndex) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (_, index) =>
                                        _HostCard(host: hosts[index]),
                                  ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _HostFilterBar extends StatelessWidget {
  final String status;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;

  const _HostFilterBar({
    required this.status,
    required this.onSearchChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Tim theo ten, email, so dien thoai',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          for (final item in const [
            ('all', 'Tat ca'),
            ('active', 'Dang hoat dong'),
            ('inactive', 'Da khoa'),
          ])
            ChoiceChip(
              label: Text(item.$2),
              selected: status == item.$1,
              onSelected: (_) => onStatusChanged(item.$1),
            ),
        ],
      ),
    );
  }
}

class _HostTable extends StatelessWidget {
  final List<AdminHostModel> hosts;

  const _HostTable({required this.hosts});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        AppCard(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Host')),
                DataColumn(label: Text('Areas')),
                DataColumn(label: Text('Rooms')),
                DataColumn(label: Text('Active contracts')),
                DataColumn(label: Text('Alerts')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Action')),
              ],
              rows: hosts
                  .map(
                    (host) => DataRow(
                      cells: [
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(host.fullName),
                              Text(
                                host.email,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkSubtext
                                      : AppColors.lightSubtext,
                                ),
                              ),
                            ],
                          ),
                          onTap: () =>
                              context.go('/admin/hosts/${host.userId}'),
                        ),
                        DataCell(Text('${host.totalAreas}')),
                        DataCell(Text('${host.totalRooms}')),
                        DataCell(Text('${host.activeContracts}')),
                        DataCell(
                          Text(
                            '${host.warningCount}',
                            style: TextStyle(
                              color: host.warningCount > 0
                                  ? AppColors.error
                                  : AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        DataCell(_HostStatusBadge(isActive: host.isActive)),
                        DataCell(
                          TextButton(
                            onPressed: () =>
                                context.go('/admin/hosts/${host.userId}'),
                            child: const Text('Chi tiet'),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _HostCard extends StatelessWidget {
  final AdminHostModel host;

  const _HostCard({required this.host});

  @override
  Widget build(BuildContext context) {
    final subtext = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSubtext
        : AppColors.lightSubtext;

    return AppCard(
      onTap: () => context.go('/admin/hosts/${host.userId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(host.fullName, style: AppTextStyles.h3),
                    const SizedBox(height: 4),
                    Text(
                      host.email,
                      style: AppTextStyles.body2.copyWith(color: subtext),
                    ),
                  ],
                ),
              ),
              _HostStatusBadge(isActive: host.isActive),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _HostMiniStat(label: 'Areas', value: '${host.totalAreas}'),
              _HostMiniStat(label: 'Rooms', value: '${host.totalRooms}'),
              _HostMiniStat(label: 'Alerts', value: '${host.warningCount}'),
              _HostMiniStat(
                label: 'Missing invoices',
                value: '${host.roomsWithoutInvoice}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HostMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _HostMiniStat({
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
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _HostStatusBadge extends StatelessWidget {
  final bool isActive;

  const _HostStatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Locked',
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
