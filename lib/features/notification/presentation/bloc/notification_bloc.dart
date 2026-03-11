import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:paypact/features/notification/domain/repositories/notification_repository.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({required NotificationRepository notificationRepository})
      : _repo = notificationRepository,
        super(const NotificationState()) {
    on<NotificationInitRequested>(_onInit);
    on<_NotificationReceived>(_onReceived);
  }

  final NotificationRepository _repo;
  StreamSubscription? _msgSub;

  Future<void> _onInit(
    NotificationInitRequested event,
    Emitter<NotificationState> emit,
  ) async {
    await _repo.requestPermission();
    final tokenResult = await _repo.getFcmToken();
    tokenResult.fold(
      (_) {},
      (token) => emit(state.copyWith(fcmToken: token)),
    );
    _msgSub?.cancel();
    _msgSub = _repo.onMessageReceived.listen(
      (msg) => add(_NotificationReceived(msg)),
    );
  }

  void _onReceived(
    _NotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(
      lastMessage: event.message,
      hasUnread: true,
    ));
  }

  @override
  Future<void> close() {
    _msgSub?.cancel();
    return super.close();
  }
}
