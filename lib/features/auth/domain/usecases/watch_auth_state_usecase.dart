import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Escucha la sesión: emite el usuario al iniciar o cerrar sesión (`null` = sin sesión).
class WatchAuthStateUseCase {
  const WatchAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.authStateChanges();
}
