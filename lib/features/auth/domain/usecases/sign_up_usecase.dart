import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Crea la cuenta y deja la sesión iniciada. Lanza `AppException` si falla.
class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({required String name, required String email, required String password}) =>
      _repository.signUp(name: name.trim(), email: email.trim(), password: password);
}
