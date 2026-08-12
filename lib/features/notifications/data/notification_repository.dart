import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/models/app_notification_model.dart';

class NotificationRepository {
  NotificationRepository({required CloudDataService cloudDataService})
    : _cloudDataService = cloudDataService;

  final CloudDataService _cloudDataService;

  Future<List<AppNotificationModel>> getNotifications(int userId) async {
    final rows = await _cloudDataService.getCollectionWhere(
      'notifications',
      field: 'user_id',
      value: userId,
    );
    final filtered =
        rows
            .where((row) => row['user_id'] == userId)
            .map(AppNotificationModel.fromMap)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  Future<int> unreadCount(int userId) async {
    final rows = await getNotifications(userId);
    return rows.where((item) => !item.isRead).length;
  }

  Future<void> setReadState({
    required int notificationId,
    required bool isRead,
  }) async {
    final row = await _cloudDataService.getDocument(
      'notifications',
      notificationId,
    );
    if (row == null) {
      return;
    }
    await _cloudDataService.setDocument('notifications', notificationId, {
      ...row,
      'is_read': isRead ? 1 : 0,
    });
  }

  Future<void> markAllRead(int userId) async {
    final unread = (await getNotifications(
      userId,
    )).where((item) => !item.isRead && item.id != null);
    await Future.wait(
      unread.map(
        (item) => setReadState(notificationId: item.id!, isRead: true),
      ),
    );
  }

  Future<void> deleteNotification({
    required int userId,
    required int notificationId,
  }) async {
    final row = await _cloudDataService.getDocument(
      'notifications',
      notificationId,
    );
    if (row == null || row['user_id'] != userId) {
      throw Exception('Notification not found.');
    }
    await _cloudDataService.deleteDocument('notifications', notificationId);
  }

  Future<void> createNotification({
    required int userId,
    required String title,
    required String body,
    required String type,
  }) async {
    final id = _cloudDataService.generateId();
    await _cloudDataService.setDocument('notifications', id, {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': 0,
      'created_at': DateTimeUtils.nowIso(),
    });
  }

  Future<void> createNotificationIfMissing({
    required int userId,
    required String title,
    required String body,
    required String type,
  }) async {
    final rows = await getNotifications(userId);
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final exists = rows.any((item) {
      final created = DateTime.tryParse(item.createdAt);
      return item.title == title &&
          item.body == body &&
          item.type == type &&
          (created == null || created.isAfter(cutoff));
    });
    if (!exists) {
      await createNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
      );
    }
  }
}
