import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _idCardCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _accountType = 'TENANT';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _idCardCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      phoneNumber: _phoneCtrl.text.trim(),
      idCardNumber: _idCardCtrl.text.trim(),
      accountType: _accountType,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đăng ký thành công! Vui lòng đăng nhập.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Đăng ký thất bại'),
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
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final loading = context.watch<AuthProvider>().loading;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Tạo tài khoản',
            style: AppTextStyles.h3.copyWith(color: fg)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Text(
                  'Điền thông tin\ncủa bạn',
                  style: AppTextStyles.h1.copyWith(color: fg),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tạo tài khoản để bắt đầu sử dụng SmartRoomMS',
                  style: AppTextStyles.body.copyWith(color: subtext),
                ),

                const SizedBox(height: 32),

                Text(
                  'Vai trò tài khoản',
                  style: AppTextStyles.label.copyWith(color: subtext),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Người Thuê'),
                        selected: _accountType == 'TENANT',
                        onSelected: (_) =>
                            setState(() => _accountType = 'TENANT'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Chủ trọ'),
                        selected: _accountType == 'HOST',
                        onSelected: (_) =>
                            setState(() => _accountType = 'HOST'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Họ và tên',
                  hint: 'Nguyễn Văn A',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập họ tên';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

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
                  label: 'Số điện thoại',
                  hint: '0901234567',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  // Số điện thoại validator
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (v.length < 10) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'CCCD / CMND',
                  hint: '001234567890',
                  controller: _idCardCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.badge_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Vui lòng nhập CCCD';
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
                    if (v == null || v.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (v.length < 6) {
                      return 'Mật khẩu tối thiểu 6 ký tự';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Xác nhận mật khẩu',
                  hint: '••••••••',
                  controller: _confirmCtrl,
                  obscure: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (v != _passCtrl.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                AppButton(
                  label: 'Tạo tài khoản',
                  onPressed: _submit,
                  loading: loading,
                  variant: AppButtonVariant.gradient,
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Đăng nhập',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
