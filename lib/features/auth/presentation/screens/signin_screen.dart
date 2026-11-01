import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/services/analytics_service.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../../shared/widgets/hamtimer_app_bar.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_header.dart';
import '../widgets/signin_form.dart';

/// Pantalla a) Registro. Crea la cuenta con correo y contraseña y guarda el
/// nombre como `displayName` (lo muestra el feed).
class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AnalyticsService>().logScreen('signin');
  }

  Future<void> _signUp(String name, String email, String password) async {
    final auth = context.read<AuthProvider>();
    final analytics = context.read<AnalyticsService>();
    final navigator = Navigator.of(context);
    final ok = await auth.signUp(name: name, email: email, password: password);
    if (ok) {
      await analytics.logEvent('sign_up', {'method': 'email'});
      // Con la sesión iniciada, AuthGate ya muestra la app debajo: se cierra
      // esta pantalla para no dejarla encima.
      navigator.popUntil((route) => route.isFirst);
    } else if (mounted && auth.errorMessage != null) {
      AppFeedback.show(context, auth.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((auth) => auth.isLoading);

    return Scaffold(
      body: Column(
        children: [
          HamtimerAppBar(
            title: 'Crear cuenta',
            leading: AppBarIconButton(
              icon: Icons.arrow_back,
              tooltip: 'Volver',
              color: AppColors.onSurface,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: const [SizedBox(width: 40)],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: 'Únete a Hamtimer',
                    subtitle: 'Cada Pomodoro que termines te da puntos para filtros',
                  ),
                  const SizedBox(height: 32),
                  SigninForm(onSubmit: _signUp, isLoading: isLoading),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
