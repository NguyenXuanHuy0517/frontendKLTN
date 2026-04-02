import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/session/session_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../data/models/rental_join_preview_model.dart';
import '../../../data/services/rental_join_service.dart';
import '../../../providers/auth_provider.dart';

class TenantRentalJoinScreen extends StatefulWidget {
  const TenantRentalJoinScreen({super.key});

  @override
  State<TenantRentalJoinScreen> createState() => _TenantRentalJoinScreenState();
}

class _TenantRentalJoinScreenState extends State<TenantRentalJoinScreen> {
  final _codeCtrl = TextEditingController();
  final _service = RentalJoinService();

  RentalJoinPreviewModel? _preview;
  String? _error;
  bool _previewLoading = false;
  bool _claimLoading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _previewInvite() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Vui long nhap ma thue');
      return;
    }

    setState(() {
      _previewLoading = true;
      _error = null;
      _preview = null;
    });

    try {
      final preview = await _service.previewInvite(code);
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageFromError(e, 'Khong the doc ma thue'));
    } finally {
      if (mounted) {
        setState(() => _previewLoading = false);
      }
    }
  }

  Future<void> _claimInvite() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Vui long nhap ma thue');
      return;
    }

    setState(() {
      _claimLoading = true;
      _error = null;
    });

    try {
      await _service.claimInvite(code);
      await SessionStore.instance.setRequiresRentalJoin(false);
      if (!mounted) return;
      context.go('/tenant/dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageFromError(e, 'Nhan phong that bai'));
    } finally {
      if (mounted) {
        setState(() => _claimLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    context.go('/login');
  }

  String _messageFromError(dynamic error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    }
    return fallback;
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
        automaticallyImplyLeading: false,
        backgroundColor: bg,
        title: Text(
          'Nhap ma thue',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          TextButton(onPressed: _logout, child: const Text('Dang xuat')),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoàn tất liên kết phòng trọ',
                style: AppTextStyles.h1.copyWith(color: fg),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhập mã thuê do chủ trọ gửi để xem trước và kích hoạt hợp đồng của bạn.',
                style: AppTextStyles.body.copyWith(color: subtext),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Mã thuê',
                hint: 'Dán mã thuê vào đây',
                controller: _codeCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'Kiểm tra mã',
                onPressed: _previewInvite,
                loading: _previewLoading,
              ),
              if ((_error ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_preview != null) ...[
                const SizedBox(height: 20),
                AppCard(
                  featured: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xác nhận thông tin hợp đồng',
                        style: AppTextStyles.h3.copyWith(color: fg),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Phòng',
                        value: '${_preview!.roomCode} - ${_preview!.areaName}',
                      ),
                      if ((_preview!.areaAddress ?? '').trim().isNotEmpty)
                        _InfoRow(
                          label: 'Dia chi',
                          value: _preview!.areaAddress!,
                        ),
                      _InfoRow(
                        label: 'Ngay thue',
                        value:
                            '${AppDateUtils.formatDate(_preview!.startDate)} - ${AppDateUtils.formatDate(_preview!.endDate)}',
                      ),
                      _InfoRow(
                        label: 'Gia phong',
                        value: CurrencyUtils.format(_preview!.actualRentPrice),
                      ),
                      _InfoRow(
                        label: 'Gia dien',
                        value: CurrencyUtils.format(_preview!.elecPrice),
                      ),
                      _InfoRow(
                        label: 'Gia nuoc',
                        value: CurrencyUtils.format(_preview!.waterPrice),
                      ),
                      _InfoRow(
                        label: 'Het han ma',
                        value: AppDateUtils.formatDateTime(_preview!.expiresAt),
                      ),
                      if ((_preview!.penaltyTerms ?? '').trim().isNotEmpty)
                        _InfoRow(
                          label: 'Dieu khoan',
                          value: _preview!.penaltyTerms!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Xac nhan nhan phong',
                  onPressed: _claimInvite,
                  loading: _claimLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: subtext),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
