import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Inicia sesión con correo y contraseña. Lanza `AppException` con el motivo si falla.
class SignInUseCase {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String email, required String password}) =>
      _repository.signIn(email: email.trim(), password: password);
}
