import 'package:paypact/features/auth/domain/entities/user_entity.dart';
import 'package:paypact/features/auth/domain/repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  const WatchAuthStateUseCase(this._repository);
  final AuthRepository _repository;
  Stream<UserEntity?> call() => _repository.authStateChanges;
}
