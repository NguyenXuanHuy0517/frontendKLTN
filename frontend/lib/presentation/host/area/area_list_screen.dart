import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../data/models/area_model.dart';
import '../../../providers/area_provider.dart';
import '../../../providers/auth_provider.dart';

class AreaListScreen extends StatefulWidget {
  const AreaListScreen({super.key});

  @override
  State<AreaListScreen> createState() => _AreaListScreenState();
}

class _AreaListScreenState extends State<AreaListScreen> {
  int? _hostId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _hostId = await context.read<AuthProvider>().getUserId();
    if (_hostId != null && mounted) {
      context.read<AreaProvider>().fetchAreas(_hostId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final area = context.watch<AreaProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Khu trọ', style: AppTextStyles.h3.copyWith(color: fg)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.accent, size: 26),
            onPressed: () => context.push('/host/areas/new'),
          ),
        ],
      ),
      body: area.loading
          ? const AppLoading()
          : area.areas.isEmpty
          ? AppEmpty(
        message: 'Chưa có khu trọ nào',
        icon: Icons.location_city_outlined,
        actionLabel: 'Thêm khu trọ',
        onAction: () => context.push('/host/areas/new'),
      )
          : RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: area.areas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) =>
              _AreaCard(area: area.areas[i], isDark: isDark),
        ),
      ),
      bottomNavigationBar: const HostBottomNav(currentIndex: 0),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final AreaModel area;
  final bool isDark;
  const _AreaCard({required this.area, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      onTap: () => context.push('/host/areas/${area.areaId}/edit'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_city_outlined,
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
                      area.areaName,
                      style: AppTextStyles.body
                          .copyWith(color: fg, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [area.ward, area.district, area.city]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(', '),
                      style:
                      AppTextStyles.bodySmall.copyWith(color: subtext),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: subtext,
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              height: 1),
          const SizedBox(height: 16),

          // Room stats
          Row(
            children: [
              _RoomStat(
                label: 'Tổng',
                value: area.totalRooms,
                color: AppColors.accent,
              ),
              _RoomStat(
                label: 'Trống',
                value: area.availableRooms,
                color: AppColors.roomAvailable,
              ),
              _RoomStat(
                label: 'Thuê',
                value: area.rentedRooms,
                color: AppColors.roomRented,
              ),
              _RoomStat(
                label: 'Bảo trì',
                value: area.maintenanceRooms,
                color: AppColors.roomMaintenance,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // View rooms button
          GestureDetector(
            onTap: () => context.push(
              '/host/rooms',
              extra: {'areaId': area.areaId},
            ),
            child: Row(
              children: [
                Text(
                  'Xem danh sách phòng',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _RoomStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: subtext),
          ),
        ],
      ),
    );
  }
}