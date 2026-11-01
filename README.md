# Hamtimer

App de productividad para estudiantes: organizas tus tareas, las trabajas con
la técnica Pomodoro, ganas puntos por cada bloque de enfoque y los gastas en
filtros faciales que se aplican **en vivo** sobre la cámara con ML Kit. Las
fotos con filtro se publican en un feed con likes.

Proyecto final de Desarrollo de Aplicaciones Móviles (ESEN, ciclo III 2026).

| | |
|---|---|
| Flutter | 3.47 (Dart 3.13) |
| Plataforma | Android (minSdk 24) |
| Estado | Provider + ChangeNotifier |
| Tareas | MockAPI (Dio) + SQLite (sqflite) con cola de sincronización |
| Firebase | Auth, Firestore, Storage, Analytics, Cloud Messaging |
| IA | Gemini API (`gemini-3.5-flash-lite`) con clave de Google AI Studio |
| Proyecto Firebase | `videofeed-grupo` (compartido con VideoFeed) |

## Flujo principal (menos de 5 minutos)

Registro → inicio de sesión → **Nueva tarea** (la IA estima los Pomodoros) →
**Dashboard** → **Pomodoro** (cada bloque da 10 puntos, completar la tarea da
25 más) → **Cámara** (comprar un filtro con puntos y tomar la foto) → **Feed**
(publicar y dar like).

## Pantallas y encargados

| Pantalla | Encargado | Archivos principales |
|---|---|---|
| a) Registro / Login | Jade | `lib/screens/login_screen.dart`, `signin_screen.dart`, `lib/widgets/auth/` |
| b) Dashboard | Gisi | `lib/screens/dashboard_screen.dart`, `lib/widgets/dashboard/` |
| c) Pomodoro | Alex M. | `lib/screens/pomodoro_screen.dart`, `lib/widgets/pomodoro/` |
| d) Nueva tarea con IA | Nehemías | `lib/screens/new_task_screen.dart`, `lib/widgets/new_task/` |
| e) Cámara, filtros y puntos | Alex (José Alas) | `lib/screens/camera_screen.dart`, `lib/widgets/camera/` |
| f) Feed y FCM | Armando | `lib/screens/feed_screen.dart`, `lib/widgets/feed/`, `lib/services/push_notification_service.dart` |

## Cómo ejecutar

```sh
flutter pub get
cp env/local.example.json env/local.json   # y pega tu clave de Gemini
flutter run --dart-define-from-file=env/dev.json --dart-define-from-file=env/local.json
```

Para presentar, el modo demo hace que los bloques duren segundos:

```sh
flutter run --dart-define-from-file=env/demo.json --dart-define-from-file=env/local.json
```

APK release:

```sh
flutter build apk --release --dart-define-from-file=env/dev.json --dart-define-from-file=env/local.json
# build/app/outputs/flutter-apk/app-release.apk
```

### Configuración (sin claves en el código)

| Variable (`env/*.json`) | Para qué |
|---|---|
| `API_BASE_URL` | URL de MockAPI (el recurso `/tasks` se agrega en el código) |
| `FAST_POMODORO` | `true` = modo demo (10 s de enfoque) |
| `GEMINI_MODEL` | Modelo de Gemini para estimar la duración (`gemini-3.5-flash-lite`, nivel gratis) |
| `GEMINI_API_KEY` | Solo en `env/local.json` (no se sube): clave de [Google AI Studio](https://aistudio.google.com/apikey) |

Gemini se llama directo a la Gemini API (`generateContent`) con la clave de AI
Studio. Sin clave, o sin red, el formulario usa el promedio del historial.
La clave queda dentro del APK: sirve para la clase, no para publicar en la
tienda (ahí iría un backend o Firebase AI Logic). `lib/firebase_options.dart` y
`android/app/google-services.json` los genera FlutterFire; identifican el
proyecto, no dan acceso (el acceso lo controlan las reglas).

### Conectar Firebase (una sola vez)

```sh
dart pub global activate flutterfire_cli
flutterfire configure --project=videofeed-grupo --platforms=android --android-package-name=sv.esen.hamtimer
firebase deploy --only firestore:rules,storage
```

En la consola de Firebase:

1. **Analytics** habilitado en el proyecto.
2. Firestore → crear `hamtimer_campaigns/bienvenida` con `{ points: 50, title: "Bienvenida" }`.
3. Messaging → Nueva campaña → tema `hamtimer_all`, dato personalizado
   `campaignId = bienvenida`.

> Las reglas `firestore.rules` y `storage.rules` incluyen también las de
> VideoFeed, porque desplegar reemplaza las del proyecto completo.

### MockAPI

Recurso `tasks` con los campos `userId, title, category, priority,
estimatedPomodoros, completedPomodoros, startAt, dueAt, isCompleted,
createdAt`. Para precargar una cuenta de prueba:

```sh
node tool/seed_mockapi.mjs https://<id>.mockapi.io <uid de Firebase>
```

## Cuentas de prueba

| Rol | Correo | Contraseña | Datos |
|---|---|---|---|
| Estudiante | `demo@hamtimer.app` | `hamtimer123` | 9 tareas (4 completadas para el historial de la IA) |

## Arquitectura

Capas, de arriba hacia abajo (cada una solo conoce a la de abajo, y por
interfaces):

```
Presentación   lib/screens/*_screen.dart  +  lib/widgets/<pantalla>/
     │            (pintan estado y traducen toques en acciones)
Estado         lib/providers/  (ChangeNotifier: Auth, Task, Pomodoro, Wallet, Feed, Connectivity)
     │
Repositorio    lib/repositories/*_repository.dart  (interfaces)
     │         └─ cached_task_repository.dart, firebase_*_repository.dart, firestore_*, prefs_*
Fuentes        lib/data/remote/  (Dio → MockAPI)     lib/data/local/  (sqflite → SQLite)
     │
Servicios      lib/services/  (Analytics, Gemini, ML Kit, FCM, conectividad)
externos       Firebase Auth · Firestore · Storage · Analytics · FCM · Gemini API · ML Kit
```

- `lib/models/`: modelos puros de Dart (no importan Flutter ni Firebase).
- `lib/core/`: configuración, tema, errores, logging, validadores y utilidades.
- `lib/main.dart` es la **raíz de composición**: el único archivo que elige
  las implementaciones concretas. Por eso las pruebas usan fakes
  (`test/fakes/`) sin tocar pantallas ni providers.

### Decisiones y costos asumidos

| Decisión | Por qué | Costo asumido |
|---|---|---|
| Carpetas `screens/` + `widgets/<pantalla>/` | Cada encargado trabaja en su carpeta sin chocar con los demás | Lo compartido vive en `widgets/common/` y `providers/` |
| Repository + interfaces | Las pantallas no saben si los datos vienen de MockAPI, SQLite o un fake | Más archivos que llamar a Dio directo |
| Offline-first en tareas | La app funciona sin red salvo el feed; los cambios se guardan en una cola de SQLite y se envían al volver la conexión | Conflictos: gana el último cambio que llega a MockAPI |
| Puntos en Firestore sin transacciones | Firestore guarda las escrituras sin red y las sube después | Las reglas validan saldo ≥ 0, pero un cliente modificado podría sumarse puntos (evitarlo requiere Cloud Functions) |
| Gemini solo para estimar Pomodoros | Uso acotado y verificable: JSON con esquema fijo | Sin red se usa el promedio del historial |
| ML Kit en el teléfono | Filtros en vivo sin internet y sin costo | Precisión limitada con poca luz |
| Proyecto Firebase compartido | Reusar Blaze y Storage de VideoFeed sin costo extra | Colecciones con prefijo `hamtimer_` y reglas combinadas |

## Modo sin conexión

| Función | Sin red |
|---|---|
| Ver, crear y completar tareas, sumar Pomodoros | Sí (cola en SQLite, se sincroniza al volver la red) |
| Ganar puntos y comprar filtros | Sí (caché de Firestore) |
| Cámara y filtros con ML Kit | Sí |
| Estimar con IA | Sí, con el promedio del historial en vez de Gemini |
| Publicar foto y ver el feed | **No** |
| Primer inicio de sesión | No (después la sesión se mantiene) |

## Calidad

```sh
flutter analyze
flutter test
```

18 pruebas (3 por encargado) en `test/<pantalla>/`, con fakes escritos a mano
en `test/fakes/`.

## Analytics

Cada pantalla registra su vista y sus eventos: `login`, `sign_up`, `logout`,
`task_filter_changed`, `task_toggled`, `ai_estimate`, `task_created`,
`pomodoro_started`, `focus_block_completed`, `pomodoro_settings_changed`,
`filter_selected`, `filter_purchased`, `photo_taken`, `photo_published`,
`post_liked`, `post_unliked`, `campaign_claimed`.
