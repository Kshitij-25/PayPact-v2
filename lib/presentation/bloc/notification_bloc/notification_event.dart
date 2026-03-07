part of 'notification_bloc.dart';

abstract class NotificationEvent {}

class NotificationInitRequested extends NotificationEvent {}

class _NotificationReceived extends NotificationEvent {
  _NotificationReceived(this.message);
  final Map<String, dynamic> message;
}
