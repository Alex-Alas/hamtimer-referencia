import 'package:flutter/material.dart';

/// Mensajes breves de retroalimentación compartidos por todas las pantallas.
abstract final class AppFeedback {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Mensaje con "Deshacer". [onClosed] recibe `true` si el usuario deshizo la
  /// acción y `false` si el aviso se cerró solo (pasaron 5 segundos).
  static void showUndo(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
    void Function(bool undone)? onClosed,
  }) {
    var undone = false;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          // Con acción, Flutter deja el aviso fijo hasta tocarlo; así se cierra a los 5 s.
          persist: false,
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () {
              undone = true;
              onUndo();
            },
          ),
        ),
      ).closed.then((_) => onClosed?.call(undone));
  }
}
