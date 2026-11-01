import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../widgets/auth_header.dart';
import '../widgets/login_form.dart';
import '../../../../core/widgets/feedback.dart';
import 'signin_screen.dart';

/// Pantalla a) Inicio de sesión (Firebase Auth, clase 23).
///
/// `AuthGate` la muestra cuando no hay sesión. Al iniciar sesión no navega:
/// `AuthProvider` cambia de estado y `AuthGate` muestra la app sola.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AnalyticsService>().logScreen('login');
  }

  Future<void> _signIn(String email, String password) async {
    final auth = context.read<AuthProvider>();
    final analytics = context.read<AnalyticsService>();
    final ok = await auth.signIn(email: email, password: password);
    if (ok) {
      await analytics.logEvent('login', {'method': 'email'});
    } else if (mounted && auth.errorMessage != null) {
      AppFeedback.show(context, auth.errorMessage!);
    }
  }

  void _openSignin() {
    context.read<AuthProvider>().clearError();
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SigninScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AuthProvider, bool>((auth) => auth.isLoading);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'Hamtimer',
                  subtitle: 'Enfócate, gana puntos y presume tus filtros',
                ),
                const SizedBox(height: 36),
                LoginForm(onSubmit: _signIn, isLoading: isLoading),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading ? null : _openSignin,
                  child: const Text.rich(
                    TextSpan(
                      text: '¿No tienes cuenta? ',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'Regístrate',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
