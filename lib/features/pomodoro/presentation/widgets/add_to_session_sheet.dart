import 'package:flutter/material.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/labels.dart';
import '../../../../core/widgets/neo_box.dart';
import '../../../../core/widgets/neo_button.dart';
import '../../../tasks/domain/entities/task.dart';

/// Hoja inferior "Agregar a la sesión": lista las tareas pendientes para
/// elegir varias a la vez. Devuelve las seleccionadas (o `null` si se cancela).
class AddToSessionSheet extends StatefulWidget {
  const AddToSessionSheet({super.key, required this.loadTasks, required this.isQueued});

  /// Fuente de las tareas pendientes (GET); se inyecta para no acoplar la hoja
  /// a un store concreto.
  final Future<List<Task>> Function() loadTasks;
  final bool Function(Task task) isQueued;

  static Future<List<Task>?> show(
    BuildContext context, {
    required Future<List<Task>> Function() loadTasks,
    required bool Function(Task task) isQueued,
  }) {
    return showModalBottomSheet<List<Task>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => AddToSessionSheet(loadTasks: loadTasks, isQueued: isQueued),
    );
  }

  @override
  State<AddToSessionSheet> createState() => _AddToSessionSheetState();
}

class _AddToSessionSheetState extends State<AddToSessionSheet> {
  late final Future<List<Task>> _tasksFuture = widget.loadTasks();
  final Map<String, Task> _selected = {};

  void _toggle(Task task) {
    setState(() {
      if (_selected.remove(task.id) == null) _selected[task.id] = task;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: NeoBox(style: NeoStyle.insetSmall, width: 40, height: 5, radius: 4),
              ),
              const SizedBox(height: 16),
              const _SheetHeader(),
              const SizedBox(height: 16),
              const SectionLabel('Pendientes'),
              Flexible(child: _buildList()),
              const SizedBox(height: 20),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return _Hint(
            error is AppException ? error.message : 'No se pudieron cargar las tareas',
          );
        }
        final tasks = snapshot.data ?? const [];
        if (tasks.isEmpty) return const _Hint('No tienes tareas pendientes.');

        return ListView.separated(
          shrinkWrap: true,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _SelectableTask(
              task: task,
              isQueued: widget.isQueued(task),
              isSelected: _selected.containsKey(task.id),
              onTap: () => _toggle(task),
            );
          },
        );
      },
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: NeoButton(
            onPressed: () => Navigator.of(context).pop(),
            radius: AppRadius.lg,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: FilledButton.icon(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context).pop(_selected.values.toList()),
            icon: const Icon(Icons.playlist_add_check),
            label: Text(_selected.isEmpty ? 'Agregar tareas' : 'Agregar ${_selected.length}'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agregar a la sesión',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          'Elige las tareas para este bloque de Pomodoro',
          style: textTheme.labelMedium?.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _SelectableTask extends StatelessWidget {
  const _SelectableTask({
    required this.task,
    required this.isQueued,
    required this.isSelected,
    required this.onTap,
  });

  final Task task;
  final bool isQueued;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final remaining = task.remainingPomodoros;
    return GestureDetector(
      // Las tareas que ya están en cola se muestran, pero no se pueden repetir.
      onTap: isQueued ? null : onTap,
      child: NeoBox(
        radius: AppRadius.lg,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _Checkbox(checked: isSelected || isQueued),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      InfoBadge(label: task.category.label, color: AppColors.tertiary, inset: true),
                      const SizedBox(width: 8),
                      const Icon(Icons.timer_outlined, size: 13, color: AppColors.primary),
                      const SizedBox(width: 2),
                      Text(
                        remaining == 1 ? '1 Pomodoro restante' : '$remaining Pomodoros restantes',
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isQueued) const InfoBadge(label: 'En cola', inset: true),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    if (!checked) {
      return const NeoBox(
        style: NeoStyle.insetSmall,
        width: 24,
        height: 24,
        radius: AppRadius.sm,
        child: Icon(Icons.add, size: 14, color: AppColors.secondary),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: const Icon(Icons.check, size: 16, color: AppColors.onPrimary),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
