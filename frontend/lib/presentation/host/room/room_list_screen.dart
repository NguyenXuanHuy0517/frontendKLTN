import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/error_retry_widget.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/list_search_field.dart';
import '../../../core/widgets/paged_load_more.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/room_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/host_room_list_provider.dart';

class RoomListScreen extends StatefulWidget {
  final int? areaId;

  const RoomListScreen({super.key, this.areaId});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen>
    with SingleTickerProviderStateMixin {
  final _tabs = const ['Tat ca', 'Trong', 'Dang thue', 'Bao tri'];
  final _statuses = const ['', 'AVAILABLE', 'RENTED', 'MAINTENANCE'];
  final _searchController = TextEditingController();

  late final TabController _tabCtrl;

  Timer? _searchDebounce;
  int? _hostId;
  String? _bootstrapError;

  bool get _hasAreaFilter => widget.areaId != null;
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

  @override
  void didUpdateWidget(covariant RoomListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.areaId == widget.areaId || _hostId == null) {
      return;
    }
    context.read<HostRoomListProvider>().bootstrap(
      hostId: _hostId!,
      areaId: widget.areaId,
    );
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
    final provider = context.read<HostRoomListProvider>();
    final initialTab = _statuses.indexOf(provider.status);
    if (initialTab >= 0 && _tabCtrl.index != initialTab) {
      _tabCtrl.index = initialTab;
    }
    _searchController.text = provider.search;
    await provider.bootstrap(hostId: hostId, areaId: widget.areaId);
  }

  void _handleTabChanged() {
    if (_tabCtrl.indexIsChanging || _hostId == null) return;
    context.read<HostRoomListProvider>().applyFilters(status: _currentStatus);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => context.read<HostRoomListProvider>().applyFilters(search: value),
    );
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

  String _areaFilterLabel() {
    final rooms = context.read<HostRoomListProvider>().state.items;
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
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

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
                child: ListSearchField(
                  controller: _searchController,
                  hintText: 'Tim theo ma phong, khu tro...',
                  onChanged: _onSearchChanged,
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
                            _areaFilterLabel(),
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
      body: _buildBody(isDark),
      bottomNavigationBar: const HostBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_bootstrapError != null) {
      return ErrorRetryWidget(message: _bootstrapError!, onRetry: _bootstrap);
    }

    final state = context.watch<HostRoomListProvider>().state;

    if (state.loading) {
      return const AppLoading();
    }

    if (state.error != null) {
      return ErrorRetryWidget(
        message: state.error!,
        onRetry: () => context.read<HostRoomListProvider>().refresh(),
      );
    }

    if (state.items.isEmpty) {
      return AppEmpty(
        message: _hasAreaFilter
            ? 'Không có phòng nào trong khu trọ này'
            : 'Không có phòng nào',
        icon: Icons.meeting_room_outlined,
        actionLabel: _tabCtrl.index == 0 ? 'Thêm phòng' : null,
        onAction: _tabCtrl.index == 0 ? _openCreateRoom : null,
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<HostRoomListProvider>().refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        itemCount:
            state.items.length + ((state.hasNext || state.loadingMore) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return PagedLoadMore(
              loading: state.loadingMore,
              hasNext: state.hasNext,
              onPressed: () => context.read<HostRoomListProvider>().loadMore(),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RoomCard(room: state.items[index], isDark: isDark),
          );
        },
      ),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/host/rooms/${room.roomId}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
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
                        Flexible(
                          child: Text(
                            'Phong ${room.roomCode}',
                            style: AppTextStyles.body.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
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
                        const Icon(
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
                              style: AppTextStyles.caption.copyWith(
                                color: subtext,
                              ),
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
        ),
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
