import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../providers/dashboard_providers.dart';
import '../security/auth_gate.dart';

/// Root widget de ConsisApp.
///
/// Todo el árbol vive detrás de <AuthGate> (PIN + biometría + ciclo de vida).
class ConsisApp extends ConsumerWidget {
  const ConsisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
    final themeMode = settings?.themeMode ?? ThemeMode.dark;

    return MaterialApp(
      title: 'ConsisApp',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      home: const AuthGate(child: DashboardScreen()),
    );
  }
}

