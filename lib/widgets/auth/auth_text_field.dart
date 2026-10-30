import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../common/field_error.dart';
import '../common/neo_box.dart';

/// Campo de texto de los formularios de acceso: un `TextFormField` dentro de
/// una cavidad neomórfica, con el error dibujado debajo.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => validator(controller.text),
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NeoBox(
            style: NeoStyle.inset,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    autofillHints: autofillHints,
                    onChanged: field.didChange,
                    onSubmitted: onSubmitted,
                    decoration: InputDecoration(
                      labelText: label,
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
          FieldError(field.errorText),
        ],
      ),
    );
  }
}
