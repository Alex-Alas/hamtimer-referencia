import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/date_labels.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../core/widgets/field_error.dart';
import '../../../../../core/widgets/neo_box.dart';
import '../../../../../core/widgets/neo_button.dart';

/// Sección "Horario": fecha y hora de inicio y de vencimiento.
///
/// Muestra debajo el resultado de la validación cruzada ([error]) y resalta
/// el bloque de vencimiento, que es el que el usuario debe corregir.
class ScheduleSection extends StatelessWidget {
  const ScheduleSection({
    super.key,
    required this.startAt,
    required this.dueAt,
    required this.onStartChanged,
    required this.onDueChanged,
    required this.error,
  });

  final DateTime startAt;
  final DateTime dueAt;
  final ValueChanged<DateTime> onStartChanged;
  final ValueChanged<DateTime> onDueChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateTimeGroup(
          title: 'Inicio',
          hint: 'Comienza la actividad',
          icon: Icons.play_circle_outline,
          accent: AppColors.primary,
          value: startAt,
          onChanged: onStartChanged,
        ),
        const SizedBox(height: 10),
        _DateTimeGroup(
          title: 'Vencimiento',
          hint: 'Meta de entrega',
          icon: Icons.event_available_outlined,
          accent: AppColors.tertiary,
          value: dueAt,
          onChanged: onDueChanged,
          hasError: error != null,
        ),
        FieldError(error),
      ],
    );
  }
}

class _DateTimeGroup extends StatelessWidget {
  const _DateTimeGroup({
    required this.title,
    required this.hint,
    required this.icon,
    required this.accent,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final String title;
  final String hint;
  final IconData icon;
  final Color accent;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool hasError;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    // Se conserva la hora elegida; solo cambia el día.
    if (picked != null) onChanged(picked.withTime(value.hour, value.minute));
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (picked != null) onChanged(value.withTime(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(hint, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
      ],
    );

    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          header,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  label: 'Fecha',
                  value: DateLabels.shortDate(value),
                  icon: Icons.calendar_today_outlined,
                  accent: accent,
                  onTap: () => _pickDate(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PickerButton(
                  label: 'Hora',
                  value: DateLabels.time(value),
                  icon: Icons.schedule,
                  accent: accent,
                  onTap: () => _pickTime(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Stack(
      children: [
        NeoBox(style: NeoStyle.insetSmall, child: body),
        if (hasError)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.6), width: 1.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NeoButton(
      onPressed: onTap,
      small: true,
      radius: AppRadius.sm,
      padding: const EdgeInsets.all(8),
      semanticLabel: '$label: $value',
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.outline,
                  ),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
