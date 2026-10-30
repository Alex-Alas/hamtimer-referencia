import 'package:firebase_auth/firebase_auth.dart';

import '../core/errors/app_exception.dart';
import '../core/logging/app_logger.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

/// Autenticación con correo y contraseña de Firebase Auth (clase 23).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() => _auth.userChanges().map(_toAppUser);

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _toAppUser(credential.user)!;
    } on FirebaseAuthException catch (error) {
      throw AppException(_message(error));
    }
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      await user.reload();
      return _toAppUser(_auth.currentUser)!;
    } on FirebaseAuthException catch (error) {
      throw AppException(_message(error));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    final email = user.email ?? '';
    return AppUser(
      uid: user.uid,
      email: email,
      // Si aún no se guardó el nombre, se usa la parte del correo antes de @.
      displayName: (user.displayName?.isNotEmpty ?? false)
          ? user.displayName!
          : email.split('@').first,
    );
  }

  /// Traduce los códigos de Firebase a mensajes para el usuario.
  String _message(FirebaseAuthException error) {
    AppLogger.warning('auth', 'FirebaseAuthException ${error.code}');
    return switch (error.code) {
      'invalid-email' => 'El correo no es válido',
      'user-disabled' => 'Esta cuenta está deshabilitada',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Correo o contraseña incorrectos',
      'email-already-in-use' => 'Ya existe una cuenta con ese correo',
      'weak-password' => 'La contraseña es muy débil',
      'too-many-requests' => 'Demasiados intentos. Espera un momento',
      'network-request-failed' => 'Sin conexión a internet',
      _ => 'No se pudo completar la operación (${error.code})',
    };
  }
}
