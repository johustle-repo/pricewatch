import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppNotificationButton extends StatelessWidget {
  const AppNotificationButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Notifications',
    onPressed: () => context.push('/notifications'),
    icon: const Icon(Icons.notifications_none_rounded),
  );
}
