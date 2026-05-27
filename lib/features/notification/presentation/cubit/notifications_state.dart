part of 'notifications_cubit.dart';

abstract class NotificationsState {}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  NotificationsLoaded(this.notifications);

  List<NotificationEntity> get unread =>
      notifications.where((n) => !n.isRead).toList();
  List<NotificationEntity> get read =>
      notifications.where((n) => n.isRead).toList();
}

class NotificationsError extends NotificationsState {
  final String message;
  NotificationsError(this.message);
}
