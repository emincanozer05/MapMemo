import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../home/presentation/screens/home_shell.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

/// Top-level router: shows a splash spinner until the first auth-state
/// event arrives, then swaps between [LoginScreen] and [HomeShell].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return const HomeShell();
    }
  }
}
