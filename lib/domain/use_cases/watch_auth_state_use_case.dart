import 'package:paypact/domain/entities/user_entity.dart';
import 'package:paypact/domain/repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  const WatchAuthStateUseCase(this._repository);
  final AuthRepository _repository;
  Stream<UserEntity?> call() => _repository.authStateChanges;
}
