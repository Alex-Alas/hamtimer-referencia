import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/field_error.dart';
import '../../../../../core/widgets/labels.dart';
import '../../../../../core/widgets/neo_box.dart';
import '../../../../../core/widgets/neo_button.dart';
import 'schedule_section.dart';
import 'task_duration_input.dart';
import 'task_form_controller.dart';
import 'task_form_fields.dart';

/// Formulario "Nueva tarea": junta los campos y los conecta al
/// [TaskFormController]. Se redibuja cada vez que el controlador cambia.
class CreateTaskForm extends StatelessWidget {
  const CreateTaskForm({
    super.key,
    required this.formKey,
    required this.controller,
    required this.onSubmit,
    required this.onEstimate,
  });

  final GlobalKey<FormState> formKey;
  final TaskFormController controller;
  final VoidCallback onSubmit;
  final VoidCallback onEstimate;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            NeoBox(
              radius: AppRadius.lg,
              padding: const EdgeInsets.all(20),
              child: _buildFields(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    const gap = SizedBox(height: 24);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Objetivo de enfoque'),
        TitleField(
          controller: controller.titleController,
          validator: controller.validateTitle,
          autovalidate: controller.submitAttempted,
        ),
        gap,
        const SectionLabel('Categoría'),
        CategorySelector(selected: controller.category, onSelected: controller.selectCategory),
        FieldError(controller.categoryError),
        gap,
        const SectionLabel('Duración estimada'),
        TaskDurationInput(
          value: controller.pomodoros,
          focusMinutes: controller.focusMinutes,
          onIncrement: controller.canIncrement ? controller.incrementPomodoros : null,
          onDecrement: controller.canDecrement ? controller.decrementPomodoros : null,
          onEstimate: onEstimate,
          isEstimating: controller.isEstimating,
          estimate: controller.estimate,
          estimateError: controller.estimateError,
        ),
        FieldError(controller.pomodorosError),
        gap,
        const SectionLabel('Nivel de prioridad'),
        PrioritySelector(selected: controller.priority, onSelected: controller.selectPriority),
        gap,
        const SectionLabel('Horario'),
        ScheduleSection(
          startAt: controller.startAt,
          dueAt: controller.dueAt,
          onStartChanged: controller.setStartAt,
          onDueChanged: controller.setDueAt,
          error: controller.scheduleError,
        ),
        const SizedBox(height: 28),
        PrimaryButton(
          label: 'Crear tarea',
          icon: Icons.add_task,
          loading: controller.isSubmitting,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
