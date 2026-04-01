// Màn hình trung tâm gửi thông báo của host, tách riêng khỏi hộp thư.
import 'package:flutter/material.dart';

import 'host_notification_screen.dart';

class HostNotificationSendScreen extends StatelessWidget {
  const HostNotificationSendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HostNotificationScreen(
      mode: HostNotificationScreenMode.sendCenter,
    );
  }
}
