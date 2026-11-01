import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../shared/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/watch_auth_state_usecase.dart';

/// Estado de la sesión.
enum AuthStatus {
  /// Todavía no se sabe (Firebase está revisando si había sesión guardada).
  unknown,
  authenticated,
  unauthenticated,
}

/// Estado global de autenticación (encargada: pantalla de Login/Registro).
///
/// `AuthGate` lo escucha para mostrar el login o la app, y el resto de
/// providers toman de aquí el `uid` del usuario.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required WatchAuthStateUseCase watchAuthState,
    required this._signIn,
    required this._signUp,
    required this._signOut,
  }) {
    _subscription = watchAuthState().listen((user) {
      _user = user;
      _status = user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
      notifyListeners();
    });
  }

  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  late final StreamSubscription<AppUser?> _subscription;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Devuelve `true` si inició sesión; si no, deja el motivo en [errorMessage].
  Future<bool> signIn({required String email, required String password}) =>
      _run(() => _signIn(email: email, password: password));

  Future<bool> signUp({required String name, required String email, required String password}) =>
      _run(() => _signUp(name: name, email: email, password: password));

  Future<void> signOut() => _signOut();

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _run(Future<AppUser> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await action();
      return true;
    } on AppException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
