import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/room_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';

class RoomListScreen extends StatefulWidget {
  final int? areaId;

  const RoomListScreen({super.key, this.areaId});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen>
    with SingleTickerProviderStateMixin {
  int? _hostId;
  late TabController _tabCtrl;
  String _search = '';

  final _tabs = const ['Tat ca', 'Trong', 'Dang thue', 'Bao tri'];
  final _statuses = const ['', 'AVAILABLE', 'RENTED', 'MAINTENANCE'];

  bool get _hasAreaFilter => widget.areaId != null;

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
    final authProvider = context.read<AuthProvider>();
    final roomProvider = context.read<RoomProvider>();
    _hostId = await authProvider.getUserId();
    if (!mounted || _hostId == null) return;

    if (_hasAreaFilter) {
      await roomProvider.fetchRoomsByArea(widget.areaId!);
      return;
    }

    await roomProvider.fetchRooms(_hostId!);
  }

  void _clearAreaFilter() {
    context.go('/host/rooms');
  }

  void _openCreateRoom() {
    if (_hasAreaFilter) {
      context.push('/host/rooms/new?areaId=${widget.areaId}');
      return;
    }
    context.push('/host/rooms/new');
  }

  List<RoomModel> _filtered(List<RoomModel> rooms, int tabIndex) {
    var list = rooms;
    final status = _statuses[tabIndex];
    if (status.isNotEmpty) {
      list = list.where((room) => room.status == status).toList();
    }
    if (_search.isNotEmpty) {
      list = list
          .where(
            (room) =>
                room.roomCode.toLowerCase().contains(_search.toLowerCase()) ||
                room.areaName.toLowerCase().contains(_search.toLowerCase()),
          )
          .toList();
    }
    return list;
  }

  String _areaFilterLabel(List<RoomModel> rooms) {
    if (rooms.isNotEmpty) {
      return 'Dang loc: ${rooms.first.areaName}';
    }
    return 'Dang loc theo khu tro #${widget.areaId}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final roomProvider = context.watch<RoomProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Phong tro', style: AppTextStyles.h3.copyWith(color: fg)),
        actions: [
          if (_hasAreaFilter)
            IconButton(
              icon: Icon(
                Icons.filter_alt_off_outlined,
                color: subtext,
                size: 22,
              ),
              onPressed: _clearAreaFilter,
            ),
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.accent, size: 26),
            onPressed: _openCreateRoom,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_hasAreaFilter ? 140 : 96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _search = value),
                  style: AppTextStyles.body.copyWith(color: fg),
                  decoration: InputDecoration(
                    hintText: 'Tim theo ma phong, khu tro...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(color: subtext),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: subtext,
                      size: 20,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkCard
                        : AppColors.lightCard,
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
              if (_hasAreaFilter)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.filter_alt_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _areaFilterLabel(roomProvider.rooms),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _clearAreaFilter,
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
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
      body: roomProvider.loading
          ? const AppLoading()
          : TabBarView(
              controller: _tabCtrl,
              children: List.generate(_tabs.length, (index) {
                final list = _filtered(roomProvider.rooms, index);
                if (list.isEmpty) {
                  return AppEmpty(
                    message: _hasAreaFilter
                        ? 'Khong co phong nao trong khu tro nay'
                        : 'Khong co phong nao',
                    icon: Icons.meeting_room_outlined,
                    actionLabel: index == 0 ? 'Them phong' : null,
                    onAction: index == 0 ? _openCreateRoom : null,
                  );
                }
                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, idx) =>
                        _RoomCard(room: list[idx], isDark: isDark),
                  ),
                );
              }),
            ),
      bottomNavigationBar: const HostBottomNav(currentIndex: 1),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final bool isDark;

  const _RoomCard({required this.room, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      onTap: () => context.push('/host/rooms/${room.roomId}'),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _statusColor(room.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.meeting_room_outlined,
              color: _statusColor(room.status),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Phong ${room.roomCode}',
                      style: AppTextStyles.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: room.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  room.areaName,
                  style: AppTextStyles.bodySmall.copyWith(color: subtext),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      CurrencyUtils.format(room.basePrice),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (room.currentTenantName != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: subtext,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          room.currentTenantName!,
                          style: AppTextStyles.caption.copyWith(color: subtext),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: subtext, size: 20),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppColors.roomAvailable;
      case 'RENTED':
        return AppColors.roomRented;
      case 'DEPOSITED':
        return AppColors.roomDeposited;
      case 'MAINTENANCE':
        return AppColors.roomMaintenance;
      default:
        return AppColors.accent;
    }
  }
}
