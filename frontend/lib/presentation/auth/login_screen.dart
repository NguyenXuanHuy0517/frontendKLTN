import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/gradient_text.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      context.go('/host/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Đăng nhập thất bại'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final loading = context.watch<AuthProvider>().loading;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64),

                // ── Logo / Brand ──────────────────────────
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.home_work_rounded,
                        color: Colors.white,
                        size: 22,
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

                const SizedBox(height: 48),

                // ── Heading ───────────────────────────────
                Text(
                  'Chào mừng\ntrở lại',
                  style: AppTextStyles.h1.copyWith(
                    color: isDark ? AppColors.darkFg : AppColors.lightFg,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập để quản lý hệ thống phòng trọ',
                  style: AppTextStyles.body.copyWith(color: subtext),
                ),

                const SizedBox(height: 40),

                // ── Form ──────────────────────────────────
                AppTextField(
                  label: 'Email',
                  hint: 'example@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Mật khẩu',
                  hint: '••••••••',
                  controller: _passCtrl,
                  obscure: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (v.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // ── Forgot password ───────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Quên mật khẩu?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Login button ──────────────────────────
                AppButton(
                  label: 'Đăng nhập',
                  onPressed: _submit,
                  loading: loading,
                  variant: AppButtonVariant.gradient,
                ),

                const SizedBox(height: 24),

                // ── Divider ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: subtext.withOpacity(0.3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'hoặc',
                        style:
                        AppTextStyles.bodySmall.copyWith(color: subtext),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: subtext.withOpacity(0.3)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Register button ───────────────────────
                AppButton(
                  label: 'Tạo tài khoản mới',
                  onPressed: () => context.push('/register'),
                  variant: AppButtonVariant.outlined,
                ),

                const SizedBox(height: 40),

                // ── Footer ────────────────────────────────
                Center(
                  child: Text(
                    'SmartRoomMS v1.0',
                    style:
                    AppTextStyles.caption.copyWith(color: subtext),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}