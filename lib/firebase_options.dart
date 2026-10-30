// ARCHIVO PROVISIONAL.
//
// Se reemplaza al correr, en la raíz del proyecto:
//
//   flutterfire configure --project=videofeed-grupo --platforms=android \
//     --android-package-name=sv.esen.hamtimer
//
// Ese comando registra la app Android en Firebase, descarga
// android/app/google-services.json y genera este archivo con los valores
// reales (no son secretos: identifican el proyecto, no dan acceso).

import 'package:firebase_core/firebase_core.dart';

abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Falta configurar Firebase: corre "flutterfire configure" (ver README).',
  );
}
