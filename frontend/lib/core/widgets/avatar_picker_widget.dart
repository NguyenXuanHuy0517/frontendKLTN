import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/avatar_upload_service.dart';

/// Widget avatar có thể nhấn để thay ảnh.
/// Dùng được ở cả màn hình chủ trọ lẫn người thuê.
///
/// Cách dùng:
/// ```dart
/// AvatarPickerWidget(
///   currentUrl: user.avatarUrl,
///   userId: user.userId,
///   onUploaded: (newUrl) {
///     // cập nhật state / provider
///   },
/// )
/// ```
class AvatarPickerWidget extends StatefulWidget {
  final String? currentUrl;
  final int userId;
  final String role; // 'HOST' | 'TENANT'
  final void Function(String newUrl)? onUploaded;
  final double size;

  const AvatarPickerWidget({
    super.key,
    this.currentUrl,
    required this.userId,
    required this.role,
    this.onUploaded,
    this.size = 90,
  });

  @override
  State<AvatarPickerWidget> createState() => _AvatarPickerWidgetState();
}

class _AvatarPickerWidgetState extends State<AvatarPickerWidget> {
  final _picker = ImagePicker();
  bool _uploading = false;
  String? _localUrl; // URL tạm sau khi upload thành công

  String? get _displayUrl => _localUrl ?? widget.currentUrl;

  Future<void> _pick(ImageSource source) async {
    Navigator.pop(context); // đóng bottom sheet

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final service = AvatarUploadService();
      final newUrl = await service.upload(
        file: File(picked.path),
        userId: widget.userId,
        role: widget.role,
      );
      if (!mounted) return;
      setState(() => _localUrl = newUrl);
      widget.onUploaded?.call(newUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cập nhật ảnh đại diện thành công'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi upload ảnh: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => _pick(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => _pick(ImageSource.gallery),
            ),
            if (_displayUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xoá ảnh đại diện',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _removeAvatar();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _removeAvatar() async {
    setState(() => _uploading = true);
    try {
      final service = AvatarUploadService();
      await service.remove(userId: widget.userId, role: widget.role);
      if (!mounted) return;
      setState(() => _localUrl = null);
      widget.onUploaded?.call('');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xoá ảnh: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final radius = size / 2;

    return GestureDetector(
      onTap: _uploading ? null : _showPicker,
      child: Stack(
        children: [
          // ── Avatar circle ──────────────────────────────────
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.1),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _uploading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              )
                  : _displayUrl != null && _displayUrl!.isNotEmpty
                  ? Image.network(
                _displayUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _defaultAvatar(size),
              )
                  : _defaultAvatar(size),
            ),
          ),

          // ── Camera badge ───────────────────────────────────
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(double size) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        color: AppColors.accent,
        size: size * 0.5,
      ),
    );
  }
}