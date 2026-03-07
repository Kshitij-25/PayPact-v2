part of 'notification_bloc.dart';

class NotificationState extends Equatable {
  const NotificationState({
    this.fcmToken,
    this.lastMessage,
    this.hasUnread = false,
  });

  final String? fcmToken;
  final Map<String, dynamic>? lastMessage;
  final bool hasUnread;

  NotificationState copyWith({
    String? fcmToken,
    Map<String, dynamic>? lastMessage,
    bool? hasUnread,
  }) => NotificationState(
        fcmToken: fcmToken ?? this.fcmToken,
        lastMessage: lastMessage ?? this.lastMessage,
        hasUnread: hasUnread ?? this.hasUnread,
      );

  @override
  List<Object?> get props => [fcmToken, lastMessage, hasUnread];
}