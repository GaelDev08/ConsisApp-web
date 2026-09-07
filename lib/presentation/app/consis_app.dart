import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_settings.dart';
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
    return MaterialApp(
      title: 'ConsisApp',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(
        backgroundColorValue:
            ref.watch(appSettingsStreamProvider).valueOrNull?.backgroundColorValue ??
                AppSettings.defaultBgColor,
      ),
      home: const AuthGate(child: DashboardScreen()),
    );
  }
}

