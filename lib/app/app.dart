import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import 'home_shell.dart';

/// Widget raíz: tema, idioma y la puerta de autenticación.
class HamtimerApp extends StatelessWidget {
  const HamtimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hamtimer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // La UI está en español. Los delegados traducen los widgets de Material
      // (selectores de fecha y hora, botones de diálogo...).
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const AuthGate(),
    );
  }
}

/// Decide qué mostrar según la sesión: cargando, login o la app.
///
/// No hay navegación manual al iniciar o cerrar sesión: cuando cambia el
/// estado de [AuthProvider], esta puerta se reconstruye sola.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>((auth) => auth.status);
    return switch (status) {
      AuthStatus.unknown => const Scaffold(body: Center(child: CircularProgressIndicator())),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.authenticated => const HomeShell(),
    };
  }
}
