import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paypact/features/group/data/invite_service.dart';

sealed class JoinGroupState {
  const JoinGroupState();
}

class JoinGroupLoading extends JoinGroupState {
  const JoinGroupLoading();
}

class JoinGroupReady extends JoinGroupState {
  const JoinGroupReady(this.preview);
  final InvitePreview preview;
}

class JoinGroupJoining extends JoinGroupState {
  const JoinGroupJoining(this.preview);
  final InvitePreview preview;
}

class JoinGroupJoined extends JoinGroupState {
  const JoinGroupJoined(this.result);
  final JoinResult result;
}

class JoinGroupFailed extends JoinGroupState {
  const JoinGroupFailed(this.message);
  final String message;
}

class JoinGroupCubit extends Cubit<JoinGroupState> {
  JoinGroupCubit(this._service, this._code) : super(const JoinGroupLoading());

  final InviteService _service;
  final String _code;

  Future<void> load() async {
    emit(const JoinGroupLoading());
    try {
      emit(JoinGroupReady(await _service.preview(_code)));
    } on InviteException catch (e) {
      emit(JoinGroupFailed(e.message));
    }
  }

  Future<void> join() async {
    final current = state;
    if (current is! JoinGroupReady) return;
    emit(JoinGroupJoining(current.preview));
    try {
      emit(JoinGroupJoined(await _service.join(_code)));
    } on InviteException catch (e) {
      emit(JoinGroupFailed(e.message));
    }
  }
}
