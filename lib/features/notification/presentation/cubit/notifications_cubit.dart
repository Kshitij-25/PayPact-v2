import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/notification/domain/entities/notification_entity.dart';
import 'package:paypact/features/notification/domain/repositories/notifications_repository.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationsRepository _repo;
  final String _userId;
  StreamSubscription<List<NotificationEntity>>? _sub;

  NotificationsCubit(this._repo, this._userId) : super(NotificationsInitial());

  void load() {
    emit(NotificationsLoading());
    _sub = _repo.watchNotifications(_userId).listen(
      (notifs) => emit(NotificationsLoaded(notifs)),
      onError: (e) => emit(NotificationsError(e.toString())),
    );
  }

  Future<void> markRead(String notifId) => _repo.markRead(_userId, notifId);

  Future<void> markAllRead() => _repo.markAllRead(_userId);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
