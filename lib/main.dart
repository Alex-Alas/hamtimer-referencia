import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/config/env.dart';
import 'core/logging/app_logger.dart';
import 'core/network/dio_client.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/analytics_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/push_notification_service.dart';
import 'features/auth/data/repository/firebase_auth_repository.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_out_usecase.dart';
import 'features/auth/domain/usecases/sign_up_usecase.dart';
import 'features/auth/domain/usecases/watch_auth_state_usecase.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/camera/data/repository/firestore_wallet_repository.dart';
import 'features/camera/domain/usecases/buy_filter_usecase.dart';
import 'features/camera/domain/usecases/claim_campaign_usecase.dart';
import 'features/camera/domain/usecases/earn_points_usecase.dart';
import 'features/camera/domain/usecases/ensure_wallet_usecase.dart';
import 'features/camera/domain/usecases/watch_wallet_usecase.dart';
import 'features/camera/presentation/providers/wallet_provider.dart';
import 'features/feed/data/repository/firebase_feed_repository.dart';
import 'features/feed/domain/usecases/publish_post_usecase.dart';
import 'features/feed/domain/usecases/set_like_usecase.dart';
import 'features/feed/domain/usecases/watch_feed_usecase.dart';
import 'features/feed/presentation/providers/feed_provider.dart';
import 'features/pomodoro/data/datasource/local_notification_pomodoro_alarm.dart';
import 'features/pomodoro/data/repository/prefs_pomodoro_settings_repository.dart';
import 'features/pomodoro/domain/usecases/load_pomodoro_settings_usecase.dart';
import 'features/pomodoro/domain/usecases/save_pomodoro_settings_usecase.dart';
import 'features/pomodoro/presentation/providers/pomodoro_provider.dart';
import 'features/pomodoro/presentation/providers/pomodoro_reward_recorder.dart';
import 'features/tasks/data/datasource/gemini_duration_estimator.dart';
import 'features/tasks/data/datasource/mockapi_task_remote_data_source.dart';
import 'features/tasks/data/datasource/sqflite_task_local_data_source.dart';
import 'features/tasks/data/repository/cached_task_repository.dart';
import 'features/tasks/domain/usecases/create_task_usecase.dart';
import 'features/tasks/domain/usecases/delete_task_usecase.dart';
import 'features/tasks/domain/usecases/estimate_task_duration_usecase.dart';
import 'features/tasks/domain/usecases/get_task_history_usecase.dart';
import 'features/tasks/domain/usecases/get_task_page_usecase.dart';
import 'features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'features/tasks/domain/usecases/update_task_usecase.dart';
import 'features/tasks/presentation/providers/task_provider.dart';
import 'firebase_options.dart';

/// Recibe los mensajes de FCM con la app cerrada o en segundo plano. Debe ser
/// una función de primer nivel; Android muestra la notificación por sí solo.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info('fcm', 'Mensaje en segundo plano ${message.messageId}');
}

/// Punto de entrada y "raíz de composición": el único lugar donde se eligen
/// las implementaciones concretas (Firebase, MockAPI, SQLite, Gemini) y se
/// conectan siguiendo Clean Architecture:
///
///   Pantalla → Provider → CasoDeUso → Repository (contrato) → RepositoryImpl → DataSource
///
/// El resto del código solo conoce contratos, por eso las pruebas pueden usar
/// fakes sin tocar pantallas ni providers.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('es');

  // Implementaciones concretas (capa data), una sola instancia de cada una.
  final authRepository = FirebaseAuthRepository();
  final taskRepository = CachedTaskRepository(
    remote: MockApiTaskRemoteDataSource(createDioClient()),
    local: SqfliteTaskLocalDataSource(),
  );
  final walletRepository = FirestoreWalletRepository();
  final feedRepository = FirebaseFeedRepository();
  final settingsRepository = PrefsPomodoroSettingsRepository();

  runApp(
    MultiProvider(
      providers: [
        // Servicios sin estado: se leen con context.read.
        Provider<AnalyticsService>(create: (_) => FirebaseAnalyticsService()),
        Provider(create: (_) => EstimateTaskDurationUseCase(GeminiDurationEstimator())),
        Provider<PushNotificationService>(
          create: (_) => PushNotificationService(),
          dispose: (_, service) => service.dispose(),
        ),

        // Estado global.
        ChangeNotifierProvider(create: (_) => ConnectivityProvider(ConnectivityPlusService())),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            watchAuthState: WatchAuthStateUseCase(authRepository),
            signIn: SignInUseCase(authRepository),
            signUp: SignUpUseCase(authRepository),
            signOut: SignOutUseCase(authRepository),
          ),
        ),

        // Estos dependen del usuario: cada vez que cambia la sesión, el
        // ProxyProvider les pasa el usuario nuevo con setUser.
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(
            getTasks: GetTasksUseCase(taskRepository),
            getTaskPage: GetTaskPageUseCase(taskRepository),
            getTaskHistory: GetTaskHistoryUseCase(taskRepository),
            createTask: CreateTaskUseCase(taskRepository),
            updateTask: UpdateTaskUseCase(taskRepository),
            deleteTask: DeleteTaskUseCase(taskRepository),
          ),
          update: (_, auth, tasks) => tasks!..setUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WalletProvider>(
          create: (_) => WalletProvider(
            watchWallet: WatchWalletUseCase(walletRepository),
            ensureWallet: EnsureWalletUseCase(walletRepository),
            earnPoints: EarnPointsUseCase(walletRepository),
            buyFilter: BuyFilterUseCase(walletRepository),
            claimCampaign: ClaimCampaignUseCase(walletRepository),
          ),
          update: (_, auth, wallet) => wallet!..setUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FeedProvider>(
          create: (_) => FeedProvider(
            watchFeed: WatchFeedUseCase(feedRepository),
            publishPost: PublishPostUseCase(feedRepository),
            setLike: SetLikeUseCase(feedRepository),
          ),
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
            loadSettings: LoadPomodoroSettingsUseCase(settingsRepository),
            saveSettings: SavePomodoroSettingsUseCase(settingsRepository),
            demoMode: Env.fastPomodoro,
            alarm: LocalNotificationPomodoroAlarm(),
          )..loadSettings(),
        ),
      ],
      child: const HamtimerApp(),
    ),
  );
}
