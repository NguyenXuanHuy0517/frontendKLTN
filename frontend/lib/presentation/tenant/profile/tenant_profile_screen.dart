import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../data/services/avatar_upload_service.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../core/widgets/avatar_picker_widget.dart';

class TenantProfileScreen extends StatefulWidget {
  const TenantProfileScreen({super.key});
  @override
  State<TenantProfileScreen> createState() => _TenantProfileScreenState();
}

class _TenantProfileScreenState extends State<TenantProfileScreen> {
  int? _userId;
  String? _avatarUrl;
  String _fullName = '';
  String _email    = '';
  String _phone    = '';
  bool _editMode   = false;
  bool _saving     = false;

  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthProvider>();
    _userId = await auth.getUserId();
    // Lấy từ AuthProvider (đã có sau khi login)
    final user = auth.user;
    if (user != null && mounted) {
      setState(() {
        _fullName  = user.fullName;
        _email     = user.email;
        _phone     = '';          // nếu AuthProvider chưa lưu phone, cần gọi API /tenant/profile
        _avatarUrl = null;        // tương tự avatar
        _nameCtrl.text  = _fullName;
        _phoneCtrl.text = _phone;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    // TODO: gọi PUT /api/tenant/profile với nameCtrl.text, phoneCtrl.text
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() { _saving = false; _editMode = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cập nhật hồ sơ thành công'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg       = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext  = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border   = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        title: Text('Hồ sơ cá nhân', style: AppTextStyles.h3.copyWith(color: fg)),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: subtext, size: 22,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          TextButton(
            onPressed: () => setState(() => _editMode = !_editMode),
            child: Text(_editMode ? 'Huỷ' : 'Sửa',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Avatar ─────────────────────────────────────
            Center(
              child: _userId == null
                  ? const AppLoading()
                  : AvatarPickerWidget(
                currentUrl: _avatarUrl,
                userId: _userId!,
                role: 'TENANT',
                size: 100,
                onUploaded: (url) =>
                    setState(() => _avatarUrl = url.isEmpty ? null : url),
              ),
            ),
            const SizedBox(height: 8),
            Text(_fullName,
                style: AppTextStyles.h3.copyWith(color: fg)),
            Text(_email,
                style: AppTextStyles.bodySmall.copyWith(color: subtext)),

            const SizedBox(height: 24),

            // ── Info card ───────────────────────────────────
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin cá nhân',
                      style: AppTextStyles.body.copyWith(
                          color: fg, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),

                  if (_editMode) ...[
                    AppTextField(
                      label: 'Họ và tên',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Số điện thoại',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Lưu thay đổi',
                      onPressed: _save,
                      loading: _saving,
                    ),
                  ] else ...[
                    _Row(Icons.person_outline_rounded, 'Họ tên', _fullName,
                        subtext, fg),
                    Divider(color: border, height: 20),
                    _Row(Icons.mail_outline_rounded,   'Email',  _email,
                        subtext, fg),
                    Divider(color: border, height: 20),
                    _Row(Icons.phone_outlined, 'Điện thoại',
                        _phone.isEmpty ? 'Chưa cập nhật' : _phone,
                        subtext, _phone.isEmpty ? subtext : fg),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Quick links ─────────────────────────────────
            AppCard(
              child: Column(children: [
                _LinkRow(Icons.description_outlined, 'Hợp đồng của tôi',
                        () => context.push('/tenant/contract'), subtext, fg),
                Divider(color: border, height: 1),
                _LinkRow(Icons.receipt_long_outlined, 'Lịch sử hóa đơn',
                        () => context.push('/tenant/invoices'), subtext, fg),
                Divider(color: border, height: 1),
                _LinkRow(Icons.report_outlined, 'Khiếu nại của tôi',
                        () => context.push('/tenant/issues'), subtext, fg),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Logout ──────────────────────────────────────
            AppCard(
              onTap: _logout,
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: AppColors.error, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Đăng xuất',
                    style: AppTextStyles.body.copyWith(
                        color: AppColors.error, fontWeight: FontWeight.w600)),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: subtext),
              ]),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 4),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color labelColor, valueColor;
  const _Row(this.icon, this.label, this.value,
      this.labelColor, this.valueColor);
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: labelColor),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.caption.copyWith(color: labelColor)),
      const SizedBox(height: 2),
      Text(value, style: AppTextStyles.body.copyWith(
          color: valueColor, fontWeight: FontWeight.w500)),
    ])),
  ]);
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color subtext, fg;
  const _LinkRow(this.icon, this.label, this.onTap, this.subtext, this.fg);
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.accent, size: 22),
    title: Text(label, style: AppTextStyles.body.copyWith(color: fg)),
    trailing: Icon(Icons.chevron_right_rounded, color: subtext, size: 20),
    onTap: onTap,
  );
}