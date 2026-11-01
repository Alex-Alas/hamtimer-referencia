import 'package:flutter/material.dart';

import '../../../../core/widgets/neo_button.dart';
import '../validators/auth_validators.dart';
import 'auth_text_field.dart';

/// Formulario de inicio de sesión (clase 19: `Form` + validadores).
///
/// Solo valida y entrega los datos en [onSubmit]; no sabe nada de Firebase.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onSubmit, required this.isLoading});

  final void Function(String email, String password) onSubmit;
  final bool isLoading;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onSubmit(_email.text.trim(), _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _email,
              label: 'Correo',
              icon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _password,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Iniciar sesión',
              icon: Icons.login,
              loading: widget.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
