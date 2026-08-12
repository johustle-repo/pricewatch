import 'package:flutter/foundation.dart';

import '../../../../shared/models/app_notification_model.dart';
import '../../data/notification_repository.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({
    required NotificationRepository notificationRepository,
  }) : _notificationRepository = notificationRepository;

  final NotificationRepository _notificationRepository;

  List<AppNotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _unreadCount = 0;

  List<AppNotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _unreadCount;

  Future<void> load(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _notificationRepository.getNotifications(userId);
      _unreadCount = await _notificationRepository.unreadCount(userId);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setReadState({
    required int userId,
    required int notificationId,
    required bool isRead,
  }) async {
    await _notificationRepository.setReadState(
      notificationId: notificationId,
      isRead: isRead,
    );
    await load(userId);
  }

  Future<void> markAllRead(int userId) async {
    if (_unreadCount == 0) return;
    await _notificationRepository.markAllRead(userId);
    await load(userId);
  }

  Future<void> delete({
    required int userId,
    required int notificationId,
  }) async {
    await _notificationRepository.deleteNotification(
      userId: userId,
      notificationId: notificationId,
    );
    await load(userId);
  }
}
