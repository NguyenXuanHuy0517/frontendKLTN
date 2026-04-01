import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';
import 'confirm_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileBottomSheet extends StatefulWidget {
  const ProfileBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => const ProfileBottomSheet(),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }

  @override
  State<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<ProfileBottomSheet> {
  String? _fullName;
  String? _email;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullName = prefs.getString(StorageKeys.fullName);
      _email = prefs.getString(StorageKeys.email);
      _role = prefs.getString(StorageKeys.role);
    });
  }

  String _getRoleLabel(String? role) {
    if (role == 'HOST') return 'Chủ trọ';
    if (role == 'TENANT') return 'Người thuê';
    return role ?? 'Người dùng';
  }

  Future<void> _handleLogout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất?',
      confirmLabel: 'Đăng xuất',
      cancelLabel: 'Hủy',
      destructive: true,
    );

    if (!mounted) return;

    if (confirmed == true) {
      await context.read<AuthProvider>().logout();
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Tài khoản của tôi',
                    style: AppTextStyles.h2.copyWith(color: fg),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: subtext),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // User Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar placeholder
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full name
                    Text(
                      'Họ và tên',
                      style: AppTextStyles.caption.copyWith(color: subtext),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fullName ?? 'Chưa cập nhật',
                      style: AppTextStyles.body.copyWith(color: fg),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    Text(
                      'Email',
                      style: AppTextStyles.caption.copyWith(color: subtext),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email ?? 'Chưa cập nhật',
                      style: AppTextStyles.body.copyWith(color: fg),
                    ),
                    const SizedBox(height: 16),

                    // Role
                    Text(
                      'Vai trò',
                      style: AppTextStyles.caption.copyWith(color: subtext),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getRoleLabel(_role),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu items
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                title: 'Chỉnh sửa hồ sơ',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to profile edit screen
                },
                isDark: isDark,
                fg: fg,
                subtext: subtext,
              ),
              _buildMenuItem(
                icon: Icons.lock_outline_rounded,
                title: 'Đổi mật khẩu',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to change password screen
                },
                isDark: isDark,
                fg: fg,
                subtext: subtext,
              ),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                title: 'Trợ giúp & Hỗ trợ',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to help screen
                },
                isDark: isDark,
                fg: fg,
                subtext: subtext,
              ),
              const SizedBox(height: 24),

              // Logout button
              AppButton(
                label: 'Đăng xuất',
                onPressed: _handleLogout,
                variant: AppButtonVariant.outlined,
                icon: Icons.logout_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    required Color fg,
    required Color subtext,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            child: Row(
              children: [
                Icon(icon, color: subtext, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.body.copyWith(color: fg),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: subtext, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
