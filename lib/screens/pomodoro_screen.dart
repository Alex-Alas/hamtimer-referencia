import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/errors/app_exception.dart';
import '../core/theme/app_colors.dart';
import '../models/pomodoro_settings.dart';
import '../models/task.dart';
import '../providers/pomodoro_provider.dart';
import '../providers/task_provider.dart';
import '../services/analytics_service.dart';
import '../widgets/common/feedback.dart';
import '../widgets/common/hamtimer_app_bar.dart';
import '../widgets/common/neo_box.dart';
import '../widgets/common/neo_button.dart';
import '../widgets/pomodoro/add_to_session_sheet.dart';
import '../widgets/pomodoro/pomodoro_dialogs.dart';
import '../widgets/pomodoro/pomodoro_settings_sheet.dart';
import '../widgets/pomodoro/pomodoro_timer.dart';
import '../widgets/pomodoro/session_task.dart';
import '../widgets/pomodoro/timer_controls.dart';

/// Pantalla c) Pomodoro: temporizador, cola de tareas de la sesión y puntos.
///
/// La pantalla solo pinta el estado de [PomodoroProvider] y traduce los toques
/// en acciones. Cuando el temporizador termina una etapa, el provider emite
/// un evento y aquí se abre el pop-up correspondiente.
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  StreamSubscription<PomodoroEvent>? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    _eventsSubscription = context.read<PomodoroProvider>().events.listen(_onPomodoroEvent);
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onPomodoroEvent(PomodoroEvent event) async {
    if (!mounted) return;
    final store = context.read<PomodoroProvider>();

    switch (event) {
      case FocusBlockFinished(:final nextBreak, :final pointsEarned, :final message):
        if (message != null) AppFeedback.show(context, message);
        unawaited(
          context.read<AnalyticsService>().logEvent('focus_block_completed', {
            'points': pointsEarned,
            'has_task': (pointsEarned > 0).toString(),
          }),
        );
        final choice = await PomodoroDialogs.showFocusFinished(
          context,
          breakLabel:
              '${nextBreak.label.toLowerCase()} '
              '(${_durationLabel(store.settings.durationOf(nextBreak))})',
          extensionLabel: '+${_durationLabel(store.settings.focusExtension)}',
          pointsEarned: pointsEarned,
        );
        switch (choice) {
          case FocusFinishedChoice.startBreak:
            store.startBreak();
          case FocusFinishedChoice.skipBreak:
            store.skipBreakAndContinue();
          case FocusFinishedChoice.extendFocus:
            store.extendFocus();
          case null:
            break; // Cerró con la X: el descanso queda listo pero en pausa.
        }

      case BreakFinished():
        final choice = await PomodoroDialogs.showBreakFinished(
          context,
          focusLabel: _durationLabel(store.settings.focus),
          extensionLabel: _durationLabel(store.settings.breakExtension),
        );
        switch (choice) {
          case BreakFinishedChoice.startNextFocus:
            store.startNextFocus();
          case BreakFinishedChoice.extendBreak:
            store.extendBreak();
          case BreakFinishedChoice.endSession:
            store.endSession();
          case null:
            break;
        }
    }
  }

  Future<void> _openAddToSession() async {
    final pomodoro = context.read<PomodoroProvider>();
    final selected = await AddToSessionSheet.show(
      context,
      loadTasks: context.read<TaskProvider>().fetchPendingTasks,
      isQueued: pomodoro.isQueued,
    );
    if (selected != null && selected.isNotEmpty) pomodoro.addToQueue(selected);
  }

  /// Marcar una tarea de la cola como terminada: PUT y fuera de la sesión.
  Future<void> _completeTask(Task task) async {
    final pomodoro = context.read<PomodoroProvider>();
    try {
      await context.read<TaskProvider>().toggleCompleted(task);
      pomodoro.removeFromQueue(task);
    } on AppException catch (error) {
      if (mounted) AppFeedback.show(context, error.message);
    }
  }

  void _toggleTimer() {
    final store = context.read<PomodoroProvider>();
    if (!store.isRunning) {
      context.read<AnalyticsService>().logEvent('pomodoro_started', {
        'phase': store.phase.name,
        'queue_size': store.queue.length,
      });
    }
    store.toggle();
  }

  Future<void> _openSettings() async {
    final store = context.read<PomodoroProvider>();
    if (store.demoMode) {
      AppFeedback.show(context, 'En modo demo las duraciones son fijas (segundos)');
      return;
    }
    final analytics = context.read<AnalyticsService>();
    final settings = await PomodoroSettingsSheet.show(context, store.settings);
    if (settings == null) return;
    await store.updateSettings(settings);
    await analytics.logEvent('pomodoro_settings_changed', {
      'focus_minutes': settings.focus.inMinutes,
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PomodoroProvider>();

    return Column(
      children: [
        HamtimerAppBar(
          title: 'Pomodoro',
          subtitle: store.demoMode ? 'Modo demo: bloques de segundos' : 'Sesión de enfoque',
          centerTitle: false,
          leading: const NeoBox(
            style: NeoStyle.raisedSmall,
            width: 40,
            height: 40,
            child: Center(child: Text('🐹', style: TextStyle(fontSize: 20))),
          ),
          actions: [
            AppBarIconButton(
              icon: Icons.tune,
              tooltip: 'Duraciones',
              onPressed: _openSettings,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Center(child: _CycleIndicator(store: store)),
              const SizedBox(height: 20),
              Center(
                child: PomodoroTimer(
                  remaining: store.remaining,
                  progress: store.progress,
                  caption: store.phase.label,
                ),
              ),
              const SizedBox(height: 24),
              TimerControls(
                isRunning: store.isRunning,
                isBreak: store.phase.isBreak,
                onToggle: _toggleTimer,
                onReset: store.reset,
                onSkip: store.skip,
              ),
              const SizedBox(height: 28),
              _SessionHeader(onAdd: _openAddToSession),
              const SizedBox(height: 12),
              if (store.queue.isEmpty)
                const _EmptyQueue()
              else
                for (final (index, task) in store.queue.indexed) ...[
                  SessionTask(
                    task: task,
                    position: index,
                    onComplete: () => _completeTask(task),
                    onRemove: () => store.removeFromQueue(task),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ],
    );
  }

  /// "25 min", o "10 s" en el modo demo.
  static String _durationLabel(Duration value) =>
      value.inMinutes >= 1 ? '${value.inMinutes} min' : '${value.inSeconds} s';
}

/// Píldoras "● Enfoque" y "Ciclo X/4" sobre el dial.
class _CycleIndicator extends StatelessWidget {
  const _CycleIndicator({required this.store});

  final PomodoroProvider store;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeoBox(
          style: NeoStyle.inset,
          radius: 999,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: store.isRunning ? AppColors.primary : AppColors.outline,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                store.phase.label,
                style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        NeoBox(
          style: NeoStyle.raisedSmall,
          radius: 999,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            'Ciclo ${store.currentBlock}/${store.settings.blocksPerCycle}',
            style: const TextStyle(fontSize: 12, color: AppColors.secondary),
          ),
        ),
      ],
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Tareas de la sesión',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        NeoButton(
          onPressed: onAdd,
          small: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Agregar tarea',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return const NeoBox(
      style: NeoStyle.insetSmall,
      padding: EdgeInsets.all(20),
      child: Text(
        'Agrega tareas para que cada bloque de enfoque sume a su progreso '
        'y te dé puntos.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
