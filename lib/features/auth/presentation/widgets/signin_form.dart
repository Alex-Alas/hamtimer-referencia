import 'package:flutter/material.dart';

import '../validators/auth_validators.dart';
import '../../../../core/widgets/neo_button.dart';
import 'auth_text_field.dart';

/// Formulario de registro. Incluye la validación cruzada "Confirmar
/// contraseña", que compara dos campos (clase 20).
class SigninForm extends StatefulWidget {
  const SigninForm({super.key, required this.onSubmit, required this.isLoading});

  final void Function(String name, String email, String password) onSubmit;
  final bool isLoading;

  @override
  State<SigninForm> createState() => _SigninFormState();
}

class _SigninFormState extends State<SigninForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_name.text.trim(), _email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _name,
            label: 'Nombre',
            icon: Icons.person_outline,
            autofillHints: const [AutofillHints.name],
            validator: AuthValidators.name,
          ),
          gap,
          AuthTextField(
            controller: _email,
            label: 'Correo',
            icon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: AuthValidators.email,
          ),
          gap,
          AuthTextField(
            controller: _password,
            label: 'Contraseña',
            icon: Icons.lock_outline,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            validator: AuthValidators.password,
          ),
          gap,
          AuthTextField(
            controller: _confirm,
            label: 'Confirmar contraseña',
            icon: Icons.lock_reset,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (value) => AuthValidators.confirmPassword(value, _password.text),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Crear cuenta',
            icon: Icons.person_add_alt_1,
            loading: widget.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
