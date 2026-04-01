import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/profile_bottom_sheet.dart';
import '../../../providers/theme_provider.dart';

class AdminShell extends StatelessWidget {
  final int currentIndex;
  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  const AdminShell({
    super.key,
    required this.currentIndex,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
  });

  static const _items = <_AdminNavItem>[
    _AdminNavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      route: '/admin/dashboard',
    ),
    _AdminNavItem(
      label: 'Hosts',
      icon: Icons.apartment_outlined,
      activeIcon: Icons.apartment_rounded,
      route: '/admin/hosts',
    ),
    _AdminNavItem(
      label: 'Rooms',
      icon: Icons.meeting_room_outlined,
      activeIcon: Icons.meeting_room_rounded,
      route: '/admin/rooms',
    ),
    _AdminNavItem(
      label: 'Revenue',
      icon: Icons.insights_outlined,
      activeIcon: Icons.insights_rounded,
      route: '/admin/revenue',
    ),
  ];

  void _goToIndex(BuildContext context, int index) {
    if (index < 0 || index >= _items.length) return;
    context.go(_items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final isWide = MediaQuery.of(context).size.width >= 960;

    if (isWide) {
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Row(
            children: [
              Container(
                width: 280,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: Border(
                    right: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: NavigationRail(
                  extended: true,
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) => _goToIndex(context, index),
                  backgroundColor: Colors.transparent,
                  indicatorColor: AppColors.accent.withValues(alpha: 0.14),
                  labelType: NavigationRailLabelType.none,
                  destinations: _items
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.activeIcon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: AppColors.gradient,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GradientText(
                              'SmartRoom',
                              style: AppTextStyles.h3,
                              colors: AppColors.gradient,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Admin console',
                          style: AppTextStyles.h2.copyWith(color: fg),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Theo doi van hanh toan bo he thong.',
                          style: AppTextStyles.body2.copyWith(color: subtext),
                        ),
                      ],
                    ),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AdminRailAction(
                          icon: isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          label: isDark ? 'Light mode' : 'Dark mode',
                          onTap: () =>
                              context.read<ThemeProvider>().toggleTheme(),
                        ),
                        const SizedBox(height: 10),
                        _AdminRailAction(
                          icon: Icons.person_outline_rounded,
                          label: 'Tai khoan',
                          onTap: () => ProfileBottomSheet.show(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTextStyles.h1.copyWith(color: fg),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style:
                                      AppTextStyles.body.copyWith(color: subtext),
                                ),
                              ],
                            ),
                          ),
                          ...actions,
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.h3.copyWith(color: fg)),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: subtext),
            ),
          ],
        ),
        actions: [
          ...actions,
          IconButton(
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          IconButton(
            onPressed: () => ProfileBottomSheet.show(context),
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.white,
                  ),
                ),
                title: const Text('SmartRoom'),
                subtitle: const Text('Admin console'),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final selected = currentIndex == index;
                    return ListTile(
                      leading: Icon(selected ? item.activeIcon : item.icon),
                      title: Text(item.label),
                      selected: selected,
                      onTap: () {
                        Navigator.of(context).pop();
                        _goToIndex(context, index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        onTap: (index) => _goToIndex(context, index),
        items: _items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AdminNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class _AdminRailAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminRailAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.body2.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}
