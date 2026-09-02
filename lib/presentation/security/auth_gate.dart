import 'package:consis_app/core/security/auth_controller.dart';
import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/presentation/providers/security_providers.dart';
import 'package:consis_app/presentation/security/lock_screen.dart';
import 'package:consis_app/presentation/security/pin_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root de sesión de ConsisApp.
///
/// - Decide qué mostrar según [AuthStatus] (setup PIN / bloqueado / libre).
/// - Observa el ciclo de vida: al ir a segundo plano marca el instante y,
///   al volver, rebloquea si transcurrió ≥ timeout configurado (0 = ya).
/// - Tras un rebloqueo con biometría activa (móvil), reintenta el lector
///   automáticamente una vez; si falla/cancela queda el teclado PIN.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Inicializa SecureStore + estado (idempotente).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = ref.read(authControllerProvider);
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        ctrl.markBackgrounded();
      case AppLifecycleState.resumed:
        ctrl.maybeRelockOnResume();
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        // `inactive` es transitorio (dialogs de sistema, app switcher):
        // no bloqueamos ahí para no molestar durante permisos biométricos.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authControllerProvider).status;

    return switch (status) {
      AuthStatus.loading => const Scaffold(
          backgroundColor: AppColors.bg,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.violet),
          ),
        ),
      AuthStatus.needsPinSetup => const PinSetupScreen(),
      AuthStatus.locked => const LockScreen(),
      AuthStatus.unlocked => widget.child,
    };
  }
}
