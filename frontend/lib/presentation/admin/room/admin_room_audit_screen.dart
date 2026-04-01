import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/admin_room_audit_model.dart';
import '../../../providers/admin_room_provider.dart';
import '../widgets/admin_shell.dart';

class AdminRoomAuditScreen extends StatefulWidget {
  const AdminRoomAuditScreen({super.key});

  @override
  State<AdminRoomAuditScreen> createState() => _AdminRoomAuditScreenState();
}

class _AdminRoomAuditScreenState extends State<AdminRoomAuditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _search = '';
  String _status = 'all';
  String _host = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await context.read<AdminRoomProvider>().fetchRoomAudit();
  }

  List<AdminRoomAuditModel> _applyFilter(List<AdminRoomAuditModel> input) {
    var items = input;
    if (_status != 'all') {
      items = items.where((item) => item.status == _status).toList();
    }
    if (_host != 'all') {
      items = items.where((item) => item.hostName == _host).toList();
    }
    if (_search.isNotEmpty) {
      final keyword = _search.toLowerCase();
      items = items.where((item) {
        return item.roomCode.toLowerCase().contains(keyword) ||
            item.areaName.toLowerCase().contains(keyword) ||
            item.hostName.toLowerCase().contains(keyword) ||
            item.currentTenantName.toLowerCase().contains(keyword);
      }).toList();
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminRoomProvider>();
    final allHosts = {
      ...provider.rooms.map((item) => item.hostName).where((item) => item.isNotEmpty),
      ...provider.missingInvoiceRooms
          .map((item) => item.hostName)
          .where((item) => item.isNotEmpty),
    }.toList()
      ..sort();
    final roomList = _applyFilter(provider.rooms);
    final missingList = _applyFilter(provider.missingInvoiceRooms);

    return AdminShell(
      currentIndex: 2,
      title: 'Room Audit',
      subtitle: 'Kiem soat phong toan he thong va cac phong thieu hoa don',
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Tai lai',
        ),
      ],
      child: provider.loading && provider.rooms.isEmpty && provider.missingInvoiceRooms.isEmpty
          ? const AppLoading()
          : provider.error != null && provider.rooms.isEmpty && provider.missingInvoiceRooms.isEmpty
              ? AppEmpty(
                  message: provider.error!,
                  icon: Icons.rule_folder_outlined,
                  actionLabel: 'Thu lai',
                  onAction: _load,
                )
              : Column(
                  children: [
                    _RoomAuditSummary(
                      totalRooms: provider.rooms.length,
                      missingInvoices: provider.missingInvoiceRooms.length,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: _RoomFilterBar(
                        hosts: allHosts,
                        host: _host,
                        status: _status,
                        onHostChanged: (value) => setState(() => _host = value),
                        onStatusChanged: (value) => setState(() => _status = value),
                        onSearchChanged: (value) => setState(() => _search = value),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.accent,
                      tabs: const [
                        Tab(text: 'Tat ca'),
                        Tab(text: 'Without invoice'),
                      ],
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.accent,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _RoomAuditBody(rooms: roomList),
                            _RoomAuditBody(rooms: missingList),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _RoomAuditSummary extends StatelessWidget {
  final int totalRooms;
  final int missingInvoices;

  const _RoomAuditSummary({
    required this.totalRooms,
    required this.missingInvoices,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tong rooms', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  Text('$totalRooms', style: AppTextStyles.h2),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppCard(
              featured: missingInvoices > 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Without invoice', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  Text(
                    '$missingInvoices',
                    style: AppTextStyles.h2.copyWith(
                      color: missingInvoices > 0 ? AppColors.error : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomFilterBar extends StatelessWidget {
  final List<String> hosts;
  final String host;
  final String status;
  final ValueChanged<String> onHostChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearchChanged;

  const _RoomFilterBar({
    required this.hosts,
    required this.host,
    required this.status,
    required this.onHostChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Tim room, area, host, tenant',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        DropdownButton<String>(
          value: host,
          items: [
            const DropdownMenuItem(value: 'all', child: Text('Tat ca host')),
            ...hosts.map(
              (item) => DropdownMenuItem(value: item, child: Text(item)),
            ),
          ],
          onChanged: (value) {
            if (value != null) onHostChanged(value);
          },
        ),
        DropdownButton<String>(
          value: status,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tat ca status')),
            DropdownMenuItem(value: 'AVAILABLE', child: Text('AVAILABLE')),
            DropdownMenuItem(value: 'DEPOSITED', child: Text('DEPOSITED')),
            DropdownMenuItem(value: 'RENTED', child: Text('RENTED')),
            DropdownMenuItem(value: 'MAINTENANCE', child: Text('MAINTENANCE')),
          ],
          onChanged: (value) {
            if (value != null) onStatusChanged(value);
          },
        ),
      ],
    );
  }
}

class _RoomAuditBody extends StatelessWidget {
  final List<AdminRoomAuditModel> rooms;

  const _RoomAuditBody({required this.rooms});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1024;

    if (rooms.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          AppEmpty(
            message: 'Khong co phong phu hop bo loc hien tai.',
            icon: Icons.filter_alt_off_outlined,
          ),
        ],
      );
    }

    if (wide) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        children: [
          AppCard(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Room')),
                  DataColumn(label: Text('Area')),
                  DataColumn(label: Text('Host')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Tenant')),
                  DataColumn(label: Text('Base price')),
                  DataColumn(label: Text('Days no invoice')),
                ],
                rows: rooms
                    .map(
                      (room) => DataRow(
                        cells: [
                          DataCell(Text(room.roomCode)),
                          DataCell(Text(room.areaName)),
                          DataCell(Text(room.hostName)),
                          DataCell(_RoomStatusBadge(status: room.status)),
                          DataCell(
                            Text(
                              room.currentTenantName.isEmpty
                                  ? '-'
                                  : room.currentTenantName,
                            ),
                          ),
                          DataCell(
                            Text(CurrencyUtils.formatCompact(room.basePrice)),
                          ),
                          DataCell(
                            Text(
                              '${room.daysWithoutInvoice}',
                              style: TextStyle(
                                color: room.hasMissingInvoice
                                    ? AppColors.error
                                    : AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
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

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: rooms.length,
      separatorBuilder: (_, separatorIndex) => const SizedBox(height: 12),
      itemBuilder: (_, index) => _RoomAuditCard(room: rooms[index]),
    );
  }
}

class _RoomAuditCard extends StatelessWidget {
  final AdminRoomAuditModel room;

  const _RoomAuditCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final subtext = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSubtext
        : AppColors.lightSubtext;

    return AppCard(
      featured: room.hasMissingInvoice,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Room ${room.roomCode}', style: AppTextStyles.h3),
              ),
              _RoomStatusBadge(status: room.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(room.areaName, style: AppTextStyles.body2.copyWith(color: subtext)),
          const SizedBox(height: 4),
          Text('Host: ${room.hostName}', style: AppTextStyles.body2.copyWith(color: subtext)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _RoomMiniStat(
                label: 'Tenant',
                value: room.currentTenantName.isEmpty ? '-' : room.currentTenantName,
              ),
              _RoomMiniStat(
                label: 'Base price',
                value: CurrencyUtils.formatCompact(room.basePrice),
              ),
              _RoomMiniStat(
                label: 'Days no invoice',
                value: '${room.daysWithoutInvoice}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _RoomMiniStat({
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

class _RoomStatusBadge extends StatelessWidget {
  final String status;

  const _RoomStatusBadge({required this.status});

  Color _color() {
    switch (status) {
      case 'AVAILABLE':
        return AppColors.available;
      case 'RENTED':
        return AppColors.rented;
      case 'DEPOSITED':
        return AppColors.deposited;
      case 'MAINTENANCE':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
