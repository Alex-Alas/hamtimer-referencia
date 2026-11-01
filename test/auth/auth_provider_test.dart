import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:hamtimer/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:hamtimer/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:hamtimer/features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'package:hamtimer/features/auth/presentation/providers/auth_provider.dart';

import '../fakes/fake_auth_repository.dart';

void main() {
  test('signIn con contraseña incorrecta deja el error y con la correcta inicia sesión', () async {
    final repository = FakeAuthRepository();
    final provider = AuthProvider(
      watchAuthState: WatchAuthStateUseCase(repository),
      signIn: SignInUseCase(repository),
      signUp: SignUpUseCase(repository),
      signOut: SignOutUseCase(repository),
    );

    final failed = await provider.signIn(email: 'jade@esen.edu.sv', password: 'mala');
    expect(failed, isFalse);
    expect(provider.errorMessage, 'Correo o contraseña incorrectos');
    expect(provider.isLoading, isFalse);

    final ok = await provider.signIn(email: 'jade@esen.edu.sv', password: 'secreta123');
    await Future<void>.delayed(Duration.zero); // deja pasar el evento del stream
    expect(ok, isTrue);
    expect(provider.errorMessage, isNull);
    expect(provider.status, AuthStatus.authenticated);
    expect(provider.user?.displayName, 'Jade');
  });
}
