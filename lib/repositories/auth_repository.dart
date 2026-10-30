import '../models/app_user.dart';

/// Contrato de autenticación.
///
/// Las pantallas y el `AuthProvider` dependen de esta interfaz; la
/// implementación con Firebase Auth está en `firebase_auth_repository.dart` y
/// en las pruebas se usa `FakeAuthRepository`. Los errores llegan como
/// `AppException` con un mensaje en español.
abstract interface class AuthRepository {
  /// Emite el usuario cada vez que inicia o cierra sesión (`null` = sin sesión).
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({required String name, required String email, required String password});

  Future<void> signOut();
}
