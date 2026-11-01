import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'core/logging/app_logger.dart';
import 'data/local/sqflite_task_local_data_source.dart';
import 'data/remote/dio_client.dart';
import 'data/remote/mockapi_task_remote_data_source.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/feed_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'providers/pomodoro_reward_recorder.dart';
import 'providers/task_provider.dart';
import 'providers/wallet_provider.dart';
import 'repositories/cached_task_repository.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/firebase_feed_repository.dart';
import 'repositories/firestore_wallet_repository.dart';
import 'repositories/prefs_pomodoro_settings_repository.dart';
import 'services/analytics_service.dart';
import 'services/connectivity_service.dart';
import 'services/duration_estimator.dart';
import 'services/gemini_duration_estimator.dart';
import 'services/pomodoro_alarm.dart';
import 'services/push_notification_service.dart';

/// Recibe los mensajes de FCM con la app cerrada o en segundo plano. Debe ser
/// una función de primer nivel; Android muestra la notificación por sí solo.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info('fcm', 'Mensaje en segundo plano ${message.messageId}');
}

/// Punto de entrada y "raíz de composición": el único lugar donde se eligen
/// las implementaciones concretas (Firebase, MockAPI, SQLite, Gemini) y se
/// conectan. El resto del código solo conoce interfaces, por eso las pruebas
/// pueden usar fakes sin tocar pantallas ni providers.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('es');

  runApp(
    MultiProvider(
      providers: [
        // Servicios sin estado: se leen con context.read.
        Provider<AnalyticsService>(create: (_) => FirebaseAnalyticsService()),
        Provider<DurationEstimator>(create: (_) => GeminiDurationEstimator()),
        Provider<PushNotificationService>(
          create: (_) => PushNotificationService(),
          dispose: (_, service) => service.dispose(),
        ),

        // Estado global.
        ChangeNotifierProvider(create: (_) => ConnectivityProvider(ConnectivityPlusService())),
        ChangeNotifierProvider(create: (_) => AuthProvider(FirebaseAuthRepository())),

        // Estos dependen del usuario: cada vez que cambia la sesión, el
        // ProxyProvider les pasa el usuario nuevo con setUser.
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(
            repository: CachedTaskRepository(
              remote: MockApiTaskRemoteDataSource(createDioClient()),
              local: SqfliteTaskLocalDataSource(),
            ),
          ),
          update: (_, auth, tasks) => tasks!..setUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(FirestoreWalletRepository()),
          update: (_, auth, wallet) => wallet!..setUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FeedProvider>(
          create: (_) => FeedProvider(FirebaseFeedRepository()),
          update: (_, auth, feed) => feed!..setUser(auth.user),
        ),

        // El temporizador registra su avance a través de las tareas y el
        // monedero, pero solo conoce la interfaz PomodoroProgressRecorder.
        ChangeNotifierProvider(
          create: (context) => PomodoroProvider(
            recorder: PomodoroRewardRecorder(
              tasks: context.read<TaskProvider>(),
              wallet: context.read<WalletProvider>(),
            ),
            settingsRepository: PrefsPomodoroSettingsRepository(),
            demoMode: Env.fastPomodoro,
            alarm: LocalNotificationPomodoroAlarm(),
          )..loadSettings(),
        ),
      ],
      child: const HamtimerApp(),
    ),
  );
}
