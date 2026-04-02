import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AdminHostStatusDialogResult {
  final String reason;
  final String note;

  const AdminHostStatusDialogResult({required this.reason, required this.note});
}

class AdminHostStatusDialog extends StatefulWidget {
  final String hostName;
  final bool activating;

  const AdminHostStatusDialog({
    super.key,
    required this.hostName,
    required this.activating,
  });

  static Future<AdminHostStatusDialogResult?> show(
    BuildContext context, {
    required String hostName,
    required bool activating,
  }) {
    return showDialog<AdminHostStatusDialogResult>(
      context: context,
      builder: (_) =>
          AdminHostStatusDialog(hostName: hostName, activating: activating),
    );
  }

  @override
  State<AdminHostStatusDialog> createState() => _AdminHostStatusDialogState();
}

class _AdminHostStatusDialogState extends State<AdminHostStatusDialog> {
  final _reasonController = TextEditingController();
  final _noteController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _errorText = 'Vui lòng nhập lý do.';
      });
      return;
    }

    Navigator.of(context).pop(
      AdminHostStatusDialogResult(
        reason: reason,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.activating ? 'Mở khóa host' : 'Khóa host',
        style: AppTextStyles.h3.copyWith(color: fg),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.activating
                  ? 'Nhập lý do mở khóa cho ${widget.hostName}.'
                  : 'Nhập lý do khóa tài khoản ${widget.hostName}.',
              style: AppTextStyles.body2.copyWith(color: subtext),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              autofocus: true,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Lý do *',
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Ghi chú thêm'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: widget.activating
                ? AppColors.success
                : AppColors.error,
          ),
          child: Text(widget.activating ? 'Mở khóa' : 'Khóa host'),
        ),
      ],
    );
  }
}
