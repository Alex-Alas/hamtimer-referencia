import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pomodoro_settings.dart';
import '../../../../core/widgets/labels.dart';
import '../../../../core/widgets/neo_box.dart';

/// Hoja inferior para elegir las duraciones del temporizador. Devuelve los
/// ajustes nuevos, o `null` si se cierra sin guardar. Quien la abre los
/// guarda en SharedPreferences a través del provider.
class PomodoroSettingsSheet extends StatefulWidget {
  const PomodoroSettingsSheet({super.key, required this.initial});

  final PomodoroSettings initial;

  static const focusOptions = [15, 20, 25, 30, 45, 50];
  static const shortBreakOptions = [3, 5, 10];
  static const longBreakOptions = [10, 15, 20, 30];

  static Future<PomodoroSettings?> show(BuildContext context, PomodoroSettings initial) {
    return showModalBottomSheet<PomodoroSettings>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => PomodoroSettingsSheet(initial: initial),
    );
  }

  @override
  State<PomodoroSettingsSheet> createState() => _PomodoroSettingsSheetState();
}

class _PomodoroSettingsSheetState extends State<PomodoroSettingsSheet> {
  late int _focus = widget.initial.focus.inMinutes;
  late int _shortBreak = widget.initial.shortBreak.inMinutes;
  late int _longBreak = widget.initial.longBreak.inMinutes;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Text(
              'Duraciones',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Enfoque (min)'),
            _MinutesPicker(
              options: PomodoroSettingsSheet.focusOptions,
              selected: _focus,
              onSelected: (value) => setState(() => _focus = value),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Descanso corto (min)'),
            _MinutesPicker(
              options: PomodoroSettingsSheet.shortBreakOptions,
              selected: _shortBreak,
              onSelected: (value) => setState(() => _shortBreak = value),
            ),
            const SizedBox(height: 16),
            const SectionLabel('Descanso largo (min)'),
            _MinutesPicker(
              options: PomodoroSettingsSheet.longBreakOptions,
              selected: _longBreak,
              onSelected: (value) => setState(() => _longBreak = value),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(
                widget.initial.copyWith(
                  focus: Duration(minutes: _focus),
                  shortBreak: Duration(minutes: _shortBreak),
                  longBreak: Duration(minutes: _longBreak),
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinutesPicker extends StatelessWidget {
  const _MinutesPicker({required this.options, required this.selected, required this.onSelected});

  final List<int> options;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final minutes in options)
          ChoiceChip(
            label: Text('$minutes'),
            selected: minutes == selected,
            onSelected: (_) => onSelected(minutes),
          ),
      ],
    );
  }
}
