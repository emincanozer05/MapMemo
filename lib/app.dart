import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/connectivity/connectivity_provider.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_gate.dart';
import 'features/memory/presentation/providers/memory_provider.dart';

class MapMemoApp extends StatelessWidget {
  const MapMemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => sl<AuthProvider>()),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => sl<ConnectivityProvider>(),
        ),
        // MemoryProvider re-subscribes to Firestore whenever the signed-in
        // user changes (see MemoryProvider.updateUser).
        ChangeNotifierProxyProvider<AuthProvider, MemoryProvider>(
          create: (_) => sl<MemoryProvider>(),
          update: (_, auth, memoryProvider) =>
              memoryProvider!..updateUser(auth.user),
        ),
      ],
      child: MaterialApp(
        title: 'MapMemo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
