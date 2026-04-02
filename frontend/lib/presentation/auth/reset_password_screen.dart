import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final token = widget.token?.trim() ?? '';
    if (token.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
      token: token,
      newPassword: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Dat lai mat khau thanh cong. Vui long dang nhap.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.go('/login');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error ?? 'Dat lai mat khau that bai'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final loading = context.watch<AuthProvider>().loading;
    final token = widget.token?.trim() ?? '';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.go('/login'),
        ),
        title: Text(
          'Dat lai mat khau',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: token.isEmpty
              ? AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lien ket khong hop le',
                        style: AppTextStyles.h3.copyWith(color: fg),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Khong tim thay token dat lai mat khau. Hay kiem tra lai lien ket trong email.',
                        style: AppTextStyles.body.copyWith(color: subtext),
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Quay lai dang nhap',
                        onPressed: () => context.go('/login'),
                        variant: AppButtonVariant.outlined,
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tạo mật khẩu mới',
                        style: AppTextStyles.h1.copyWith(color: fg),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhập mật khẩu mới để hoàn tất quá trình khôi phục tài khoản.',
                        style: AppTextStyles.body.copyWith(color: subtext),
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        label: 'Mật khẩu mới',
                        hint: '••••••••',
                        controller: _passwordCtrl,
                        obscure: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu mới';
                          }
                          if (value.length < 6) {
                            return 'Mật khẩu tối thiểu 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Xac nhan mat khau',
                        hint: '••••••••',
                        controller: _confirmCtrl,
                        obscure: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui long xac nhan mat khau';
                          }
                          if (value != _passwordCtrl.text) {
                            return 'Mat khau xac nhan khong khop';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        label: 'Cap nhat mat khau',
                        onPressed: loading ? null : _submit,
                        loading: loading,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
