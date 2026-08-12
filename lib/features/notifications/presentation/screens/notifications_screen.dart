import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/models/app_notification_model.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_shell_menu_button.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/responsive_page.dart';
import '../../../../shared/widgets/shimmer_skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthController>().currentUser?.id;
      if (userId != null) {
        context.read<NotificationController>().load(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final controller = context.watch<NotificationController>();
    final userId = auth.currentUser?.id;
    final grouped = _groupNotifications(controller.notifications);
    final narrow = MediaQuery.sizeOf(context).width < 390;
    final useWebShell = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      appBar: useWebShell
          ? null
          : AppBar(
              leading: const AppShellMenuButton(),
              title: const Text('Notifications'),
              actions: [
                if (userId != null && controller.unreadCount > 0)
                  narrow
                      ? IconButton(
                          tooltip: 'Mark all as read',
                          onPressed: controller.isLoading
                              ? null
                              : () => controller.markAllRead(userId),
                          icon: const Icon(Icons.done_all_rounded),
                        )
                      : TextButton.icon(
                          onPressed: controller.isLoading
                              ? null
                              : () => controller.markAllRead(userId),
                          icon: const Icon(Icons.done_all_rounded, size: 18),
                          label: const Text('Read all'),
                        ),
                const SizedBox(width: 8),
              ],
            ),
      body: userId == null
          ? const SizedBox.shrink()
          : AppBackground(
              child: ResponsivePage(
                maxWidth: 1120,
                expandHeight: true,
                horizontalPadding: 0,
                topPadding: 0,
                bottomPadding: 0,
                edgeToEdgeDesktopOnly: true,
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<NotificationController>().load(userId),
                  child: controller.isLoading
                      ? const ListLoadingView(cardCount: 5)
                      : controller.error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            EmptyStateView(
                              title: 'Updates unavailable',
                              message: controller.error!,
                              icon: Icons.cloud_off_outlined,
                              action: FilledButton.icon(
                                onPressed: () => controller.load(userId),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Try again'),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                gradient: AppColors.heroGradientFor(context),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F7A153E),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alerts & updates',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Price spikes, report reviews, and watched-item updates land here first.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.86,
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _NotificationMetric(
                                          label: 'Unread',
                                          value: '${controller.unreadCount}',
                                          icon:
                                              Icons.mark_email_unread_outlined,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _NotificationMetric(
                                          label: 'Total updates',
                                          value:
                                              '${controller.notifications.length}',
                                          icon: Icons.notifications_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            if (controller.notifications.isEmpty)
                              const EmptyStateView(
                                title: 'No notifications yet',
                                message:
                                    'Alerts and report updates will appear here.',
                                icon: Icons.notifications_none_rounded,
                              )
                            else
                              ...grouped.entries.expand((entry) {
                                return [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 4,
                                      bottom: AppSpacing.md,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          entry.key,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color:
                                                    AppColors.textSecondaryFor(
                                                      context,
                                                    ),
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.borderFor(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...entry.value.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _NotificationCard(
                                        item: item,
                                        onDelete: item.id == null
                                            ? null
                                            : () => controller.delete(
                                                userId: userId,
                                                notificationId: item.id!,
                                              ),
                                        onToggleRead: () {
                                          final notificationId = item.id;
                                          if (notificationId == null) {
                                            return;
                                          }
                                          controller.setReadState(
                                            userId: userId,
                                            notificationId: notificationId,
                                            isRead: !item.isRead,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ];
                              }),
                          ],
                        ),
                ),
              ),
            ),
    );
  }

  Map<String, List<AppNotificationModel>> _groupNotifications(
    List<AppNotificationModel> notifications,
  ) {
    final grouped = <String, List<AppNotificationModel>>{};
    for (final item in notifications) {
      final key = AppFormatters.date(item.createdAt);
      grouped.putIfAbsent(key, () => <AppNotificationModel>[]).add(item);
    }
    return grouped;
  }
}

class _NotificationMetric extends StatelessWidget {
  const _NotificationMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: .82), size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onToggleRead,
    required this.onDelete,
  });

  final AppNotificationModel item;
  final VoidCallback? onToggleRead;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final visual = _NotificationVisual.fromType(item.type);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead
              ? AppColors.borderFor(context)
              : AppColors.primary.withValues(alpha: .24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowFor(context).withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(visual.icon, color: visual.color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!item.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Tooltip(
                      message: item.isRead ? 'Mark unread' : 'Mark read',
                      child: InkWell(
                        onTap: onToggleRead,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundFor(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.borderFor(context),
                            ),
                          ),
                          child: Icon(
                            item.isRead
                                ? Icons.mark_email_unread_outlined
                                : Icons.done_rounded,
                            size: 17,
                            color: AppColors.textSecondaryFor(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: 'Delete notification',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.45),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(visual.icon, size: 14, color: visual.color),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        visual.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: visual.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppFormatters.dateTime(item.createdAt),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationVisual {
  const _NotificationVisual({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  factory _NotificationVisual.fromType(String type) {
    switch (type) {
      case 'price_increase':
        return const _NotificationVisual(
          label: 'Price increase',
          icon: Icons.trending_up_rounded,
          color: AppColors.warning,
        );
      case 'report_status_update':
        return const _NotificationVisual(
          label: 'Report update',
          icon: Icons.flag_rounded,
          color: AppColors.sky,
        );
      default:
        return const _NotificationVisual(
          label: 'Watchlist update',
          icon: Icons.bookmark_rounded,
          color: AppColors.primaryDark,
        );
    }
  }
}
