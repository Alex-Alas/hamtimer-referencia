import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/services/analytics_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/hamtimer_app_bar.dart';
import '../../domain/entities/duration_estimate.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/estimate_task_duration_usecase.dart';
import '../providers/task_provider.dart';
import '../widgets/new_task/create_task_form.dart';
import '../widgets/new_task/task_form_controller.dart';

/// Pantalla d) Nueva tarea: formulario con validaciones, estimación de
/// Pomodoros con Gemini y POST a MockAPI (o a la cola de SQLite sin red).
class NewTaskScreen extends StatefulWidget {
  const NewTaskScreen({super.key, required this.onClose, required this.onCreated});

  /// Botón X: vuelve al dashboard sin guardar.
  final VoidCallback onClose;

  /// Se llama tras crear la tarea.
  final ValueChanged<Task> onCreated;

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TaskFormController _controller;

  @override
  void initState() {
    super.initState();
    final tasks = context.read<TaskProvider>();
    _controller = TaskFormController(
      onSubmit: tasks.create,
      estimateTaskDuration: context.read<EstimateTaskDurationUseCase>(),
      loadHistory: tasks.fetchHistory,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Cancelar: si ya hay datos escritos, pide confirmar antes de descartarlos.
  Future<void> _close() async {
    if (!_controller.hasChanges) {
      widget.onClose();
      return;
    }
    FocusScope.of(context).unfocus();
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar la tarea?'),
        content: const Text('Lo que escribiste se perderá.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) widget.onClose();
  }

  Future<void> _estimate() async {
    FocusScope.of(context).unfocus();
    final analytics = context.read<AnalyticsService>();
    final estimate = await _controller.estimateDuration();
    if (estimate == null) return;
    await analytics.logEvent('ai_estimate', {
      'source': estimate.source.name,
      'pomodoros': estimate.pomodoros,
      'category': _controller.category!.apiValue,
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final analytics = context.read<AnalyticsService>();
    final isTitleValid = _formKey.currentState?.validate() ?? false;
    final created = await _controller.submit(isTitleValid: isTitleValid);
    if (!mounted) return;
    if (created != null) {
      await analytics.logEvent('task_created', {
        'category': created.category.apiValue,
        'pomodoros': created.estimatedPomodoros,
        'used_ai': (_controller.estimate?.source == EstimateSource.ai).toString(),
      });
      widget.onCreated(created);
    } else if (_controller.submitError != null) {
      AppFeedback.show(context, _controller.submitError!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HamtimerAppBar(
          title: 'Nueva tarea',
          subtitle: 'La IA puede estimar cuántos Pomodoros toma',
          centerTitle: false,
          leading: AppBarIconButton(
            icon: Icons.close,
            tooltip: 'Cancelar',
            color: AppColors.onSurface,
            onPressed: _close,
          ),
        ),
        Expanded(
          child: CreateTaskForm(
            formKey: _formKey,
            controller: _controller,
            onSubmit: _submit,
            onEstimate: _estimate,
          ),
        ),
      ],
    );
  }
}
