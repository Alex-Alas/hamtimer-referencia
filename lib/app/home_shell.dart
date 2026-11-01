import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../features/camera/presentation/providers/wallet_provider.dart';
import '../features/camera/presentation/screens/camera_screen.dart';
import '../features/feed/presentation/screens/feed_screen.dart';
import '../features/pomodoro/presentation/screens/pomodoro_screen.dart';
import '../features/tasks/domain/entities/task.dart';
import '../features/tasks/presentation/providers/task_provider.dart';
import '../features/tasks/presentation/screens/dashboard_screen.dart';
import '../features/tasks/presentation/screens/new_task_screen.dart';
import '../shared/logging/app_logger.dart';
import '../shared/providers/connectivity_provider.dart';
import '../shared/services/analytics_service.dart';
import '../shared/services/push_notification_service.dart';
import '../shared/widgets/bottom_nav_bar.dart';
import '../shared/widgets/feedback.dart';

/// Contenedor de la app con sesión iniciada: barra inferior y las cinco
/// pantallas en un [IndexedStack].
///
/// - Las pestañas no se destruyen al cambiar: la lista conserva su scroll y el
///   Pomodoro sigue escuchando al temporizador para abrir sus pop-ups.
/// - Cada cambio de pestaña registra la pantalla en Analytics.
/// - Escucha las notificaciones de FCM (campañas de puntos) y la conexión:
///   al volver la red sincroniza las tareas creadas sin conexión.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.dashboard;

  /// Para salir con el botón atrás hay que tocarlo dos veces seguidas.
  DateTime? _lastBackPress;

  /// Cambia cada vez que se abre "Nueva": la `key` nueva obliga a crear un
  /// formulario limpio en lugar de mostrar el que quedó a medias.
  int _formSession = 0;

  StreamSubscription<PushMessage>? _pushSubscription;
  late final ConnectivityProvider _connectivity;
  bool _wasOnline = true;

  @override
  void initState() {
    super.initState();
    final analytics = context.read<AnalyticsService>();
    unawaited(analytics.logScreen(_tab.screenName));

    _connectivity = context.read<ConnectivityProvider>()..addListener(_onConnectivityChanged);
    _wasOnline = _connectivity.isOnline;

    final push = context.read<PushNotificationService>();
    _pushSubscription = push.messages.listen(_onPushMessage);
    // Se pide el permiso de notificaciones ya con sesión, no en el login.
    push.init().catchError((Object error) {
      AppLogger.warning('fcm', 'No se pudo iniciar FCM: $error');
    });
  }

  @override
  void dispose() {
    _pushSubscription?.cancel();
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _selectTab(HomeTab tab) {
    if (tab == _tab) return;
    setState(() {
      if (tab == HomeTab.newTask) _formSession++;
      _tab = tab;
    });
    context.read<AnalyticsService>().logScreen(tab.screenName);
  }

  /// Botón atrás: desde otra pestaña vuelve a Tareas; desde Tareas avisa y
  /// sale solo si se toca otra vez en los siguientes 2 segundos.
  void _onBackPressed(bool didPop, Object? result) {
    if (didPop) return;
    if (_tab != HomeTab.dashboard) {
      _selectTab(HomeTab.dashboard);
      return;
    }
    final now = DateTime.now();
    final last = _lastBackPress;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    AppFeedback.show(context, 'Toca otra vez para salir');
  }

  void _onTaskCreated(Task task) {
    _selectTab(HomeTab.dashboard);
    final offline = !context.read<ConnectivityProvider>().isOnline;
    AppFeedback.show(
      context,
      offline
          ? 'Tarea "${task.title}" guardada; se enviará al volver la red'
          : 'Tarea "${task.title}" creada',
    );
  }

  void _onConnectivityChanged() {
    final online = _connectivity.isOnline;
    if (online && !_wasOnline) {
      AppFeedback.show(context, 'Conexión recuperada: sincronizando tareas');
      context.read<TaskProvider>().refresh();
    }
    _wasOnline = online;
  }

  /// Notificación de FCM en primer plano o tocada desde la bandeja. Si trae
  /// `campaignId`, regala puntos (una sola vez por campaña).
  Future<void> _onPushMessage(PushMessage message) async {
    final wallet = context.read<WalletProvider>();
    final analytics = context.read<AnalyticsService>();
    final campaignId = message.campaignId;
    if (campaignId != null) {
      try {
        final points = await wallet.claimCampaign(campaignId);
        await analytics.logEvent('campaign_claimed', {'campaign': campaignId, 'points': points});
        if (!mounted) return;
        AppFeedback.show(
          context,
          points > 0 ? '🎁 ¡Recibiste $points puntos para filtros!' : 'Ya cobraste esta campaña',
        );
      } on Exception catch (error) {
        AppLogger.error('fcm', 'No se pudo cobrar la campaña', error);
      }
      return;
    }
    if (!mounted) return;
    final text = [message.title, message.body].whereType<String>().join(': ');
    if (text.isNotEmpty) AppFeedback.show(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBackPressed,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _tab.index,
            children: [
              const DashboardScreen(),
              const PomodoroScreen(),
              NewTaskScreen(
                key: ValueKey(_formSession),
                onClose: () => _selectTab(HomeTab.dashboard),
                onCreated: _onTaskCreated,
              ),
              CameraScreen(
                isActive: _tab == HomeTab.camera,
                onPublished: () => _selectTab(HomeTab.feed),
              ),
              const FeedScreen(),
            ],
          ),
        ),
        bottomNavigationBar: HomeBottomNavBar(selected: _tab, onSelected: _selectTab),
      ),
    );
  }
}
