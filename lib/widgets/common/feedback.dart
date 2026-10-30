import 'package:flutter/material.dart';

/// Mensajes breves de retroalimentación compartidos por todas las pantallas.
abstract final class AppFeedback {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
