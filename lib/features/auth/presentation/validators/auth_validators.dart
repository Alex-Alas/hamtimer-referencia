/// Validaciones de los formularios de registro e inicio de sesión.
///
/// Son funciones puras: reciben el texto y devuelven `null` si es válido o el
/// mensaje de error. Se conectan al `validator` de cada `TextFormField`.
abstract final class AuthValidators {
  static const int minPasswordLength = 6;
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu nombre';
    if (text.length < 2) return 'El nombre es muy corto';
    if (text.length > 40) return 'Máximo 40 caracteres';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo';
    if (!_email.hasMatch(text)) return 'Correo no válido';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe tu contraseña';
    if (text.length < minPasswordLength) {
      return 'Mínimo $minPasswordLength caracteres';
    }
    return null;
  }

  /// Validación cruzada: compara con el valor del otro campo (clase 20).
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Repite tu contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }
}
