import 'dart:async';

import 'package:hamtimer/core/errors/app_exception.dart';
import 'package:hamtimer/models/app_user.dart';
import 'package:hamtimer/repositories/auth_repository.dart';

/// Auth en memoria: acepta un solo usuario con la contraseña [validPassword].
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.validPassword = 'secreta123'});

  final String validPassword;
  final _controller = StreamController<AppUser?>.broadcast();
  final List<String> signInCalls = [];

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    signInCalls.add(email);
    if (password != validPassword) throw const AppException('Correo o contraseña incorrectos');
    final user = AppUser(uid: 'uid-1', email: email, displayName: 'Jade');
    _controller.add(user);
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final user = AppUser(uid: 'uid-1', email: email, displayName: name);
    _controller.add(user);
    return user;
  }

  @override
  Future<void> signOut() async => _controller.add(null);
}
