import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/avatar_picker_widget.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../data/models/tenant_profile_model.dart';
import '../../../data/services/tenant_profile_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';

class TenantProfileScreen extends StatefulWidget {
  const TenantProfileScreen({super.key});

  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  final _profileService = TenantProfileService();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  int? _userId;
  String? _avatarUrl;
  String _fullName = '';
  String _email = '';
  String _phone = '';
  bool _editMode = false;
  bool _loadingProfile = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    final cachedUser = auth.user;
    final userId = await auth.getUserId() ?? cachedUser?.userId;

    if (!mounted) {
      return;
    }

    if (cachedUser != null) {
      setState(() {
        _fullName = cachedUser.fullName;
        _email = cachedUser.email;
        _nameCtrl.text = cachedUser.fullName;
      });
    }

    if (userId == null) {
      setState(() => _loadingProfile = false);
      _showSnackBar('Khong tim thay thong tin tai khoan.', AppColors.error);
      return;
    }

    setState(() {
      _userId = userId;
      _loadingProfile = true;
    });

    try {
      final profile = await _profileService.getProfile(userId);
      if (!mounted) {
        return;
      }
      _applyProfile(profile);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_formatError('Khong the tai ho so', e), AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  Future<void> _save() async {
    final userId = _userId;
    final fullName = _nameCtrl.text.trim();
    final phoneNumber = _phoneCtrl.text.trim();

    if (userId == null) {
      _showSnackBar('Khong tim thay tai khoan de cap nhat.', AppColors.error);
      return;
    }
    if (fullName.isEmpty) {
      _showSnackBar('Ho ten khong duoc de trong.', AppColors.error);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final profile = await _profileService.updateProfile(
        userId: userId,
        fullName: fullName,
        phoneNumber: phoneNumber,
        avatarUrl: _avatarUrl,
      );
      if (!mounted) {
        return;
      }
      _applyProfile(profile);
      setState(() => _editMode = false);
      _showSnackBar('Cap nhat ho so thanh cong.', AppColors.success);
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showSnackBar(_formatError('Khong the cap nhat ho so', e), AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  void _toggleEditMode() {
    setState(() {
      if (_editMode) {
        _nameCtrl.text = _fullName;
        _phoneCtrl.text = _phone;
      }
      _editMode = !_editMode;
    });
  }

  void _applyProfile(TenantProfileModel profile) {
    setState(() {
      _userId = profile.userId;
      _fullName = profile.fullName;
      _email = profile.email;
      _phone = profile.phoneNumber;
      _avatarUrl = _sanitizeAvatarUrl(profile.avatarUrl);
      _nameCtrl.text = profile.fullName;
      _phoneCtrl.text = profile.phoneNumber;
    });
  }

  String? _sanitizeAvatarUrl(String? url) {
    if (url == null) {
      return null;
    }
    final trimmed = url.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatError(String prefix, Object error) {
    final message = error.toString();
    if (message.isEmpty) {
      return prefix;
    }
    return '$prefix: $message';
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text(
          'Ho so ca nhan',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: subtext,
              size: 22,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          TextButton(
            onPressed: (_loadingProfile || _saving) ? null : _toggleEditMode,
            child: Text(
              _editMode ? 'Huy' : 'Sua',
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
      body: _loadingProfile
          ? const AppLoading()
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Center(
                      child: _userId == null
                          ? const AppLoading()
                          : AvatarPickerWidget(
                              currentUrl: _avatarUrl,
                              userId: _userId!,
                              role: 'TENANT',
                              size: 100,
                              onUploaded: (url) {
                                setState(() {
                                  _avatarUrl = url.trim().isEmpty ? null : url;
                                });
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fullName,
                      style: AppTextStyles.h3.copyWith(color: fg),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      _email,
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thong tin ca nhan',
                            style: AppTextStyles.body.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_editMode) ...[
                            AppTextField(
                              label: 'Ho va ten',
                              controller: _nameCtrl,
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              label: 'So dien thoai',
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              label: 'Luu thay doi',
                              onPressed: _save,
                              loading: _saving,
                            ),
                          ] else ...[
                            _Row(
                              Icons.person_outline_rounded,
                              'Ho ten',
                              _fullName,
                              subtext,
                              fg,
                            ),
                            Divider(color: border, height: 20),
                            _Row(
                              Icons.mail_outline_rounded,
                              'Email',
                              _email,
                              subtext,
                              fg,
                            ),
                            Divider(color: border, height: 20),
                            _Row(
                              Icons.phone_outlined,
                              'Dien thoai',
                              _phone.isEmpty ? 'Chua cap nhat' : _phone,
                              subtext,
                              _phone.isEmpty ? subtext : fg,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        children: [
                          _LinkRow(
                            Icons.description_outlined,
                            'Hop dong cua toi',
                            () => context.push('/tenant/contract'),
                            subtext,
                            fg,
                          ),
                          Divider(color: border, height: 1),
                          _LinkRow(
                            Icons.receipt_long_outlined,
                            'Lich su hoa don',
                            () => context.push('/tenant/invoices'),
                            subtext,
                            fg,
                          ),
                          Divider(color: border, height: 1),
                          _LinkRow(
                            Icons.report_outlined,
                            'Khieu nai cua toi',
                            () => context.push('/tenant/issues'),
                            subtext,
                            fg,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      onTap: _logout,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Dang xuat',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, color: subtext),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 4),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _Row(
    this.icon,
    this.label,
    this.value,
    this.labelColor,
    this.valueColor,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: labelColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: labelColor),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color subtext;
  final Color fg;

  const _LinkRow(
    this.icon,
    this.label,
    this.onTap,
    this.subtext,
    this.fg,
  );

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.accent, size: 22),
      title: Text(label, style: AppTextStyles.body.copyWith(color: fg)),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: subtext,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
