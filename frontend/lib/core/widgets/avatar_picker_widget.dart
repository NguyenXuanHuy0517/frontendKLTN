import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/avatar_upload_service.dart';
import '../theme/app_colors.dart';

class AvatarPickerWidget extends StatefulWidget {
  final String? currentUrl;
  final int userId;
  final String role;
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
  String? _localUrl;

  String? get _displayUrl => _localUrl ?? widget.currentUrl;

  Future<void> _pick(ImageSource source) async {
    Navigator.pop(context);

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() => _uploading = true);
    try {
      final service = AvatarUploadService();
      final newUrl = await service.upload(
        file: File(picked.path),
        userId: widget.userId,
        role: widget.role,
      );
      if (!mounted) {
        return;
      }

      setState(() => _localUrl = newUrl);
      widget.onUploaded?.call(newUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cap nhat anh dai dien thanh cong'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi upload anh: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
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
              title: const Text('Chup anh'),
              onTap: () => _pick(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chon tu thu vien'),
              onTap: () => _pick(ImageSource.gallery),
            ),
            if (_displayUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Xoa anh dai dien',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
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
      if (!mounted) {
        return;
      }

      setState(() => _localUrl = null);
      widget.onUploaded?.call('');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Da xoa anh dai dien'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi xoa anh: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return GestureDetector(
      onTap: _uploading ? null : _showPicker,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
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
                          errorBuilder: (context, error, stackTrace) =>
                              _defaultAvatar(size),
                        )
                      : _defaultAvatar(size),
            ),
          ),
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
