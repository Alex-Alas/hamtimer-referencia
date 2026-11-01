import 'package:flutter_test/flutter_test.dart';
import 'package:hamtimer/features/auth/presentation/validators/auth_validators.dart';

void main() {
  test('los validadores de registro rechazan datos inválidos y aceptan los buenos', () {
    expect(AuthValidators.email(''), 'Escribe tu correo');
    expect(AuthValidators.email('jade@'), 'Correo no válido');
    expect(AuthValidators.email('jade@esen.edu.sv'), isNull);

    expect(AuthValidators.password('123'), 'Mínimo 6 caracteres');
    expect(AuthValidators.password('secreta123'), isNull);

    // Validación cruzada: compara con el otro campo.
    expect(AuthValidators.confirmPassword('otra', 'secreta123'), 'Las contraseñas no coinciden');
    expect(AuthValidators.confirmPassword('secreta123', 'secreta123'), isNull);
  });
}
