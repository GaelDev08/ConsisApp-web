import 'dart:async';

import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/presentation/providers/security_providers.dart';
import 'package:consis_app/presentation/security/widgets/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pantalla de bloqueo: PIN + botón biométrico rápido.
///
/// - Dispara automáticamente el lector biométrico una vez por sesión
///   si está habilitado y disponible (móvil).
/// - En web nunca aparece el botón biométrico (`hasBiometrics=false`).
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _entry = '';
  bool _hasError = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider).tryAutoBiometric();
      _syncTicker();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Mantiene el contador visual de cooldown actualizado segundo a segundo.
  void _syncTicker() {
    final ctrl = ref.read(authControllerProvider);
    if (!ctrl.isCoolingDown) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (!ref.read(authControllerProvider).isCoolingDown) {
        _ticker?.cancel();
      }
    });
  }

  void _onDigit(String digit) {
    final ctrl = ref.read(authControllerProvider);
    if (ctrl.isCoolingDown || _entry.length >= 4) return;

    setState(() {
      _entry += digit;
      _hasError = false;
    });

    if (_entry.length == 4) {
      // Pequeña pausa para que el usuario vea los 4 puntos llenos.
      Future.delayed(const Duration(milliseconds: 140), _submit);
    }
  }

  Future<void> _submit() async {
    final entry = _entry;
    if (entry.length != 4) return;

    final ctrl = ref.read(authControllerProvider);
    final ok = await ctrl.unlockWithPin(entry);
    if (!mounted) return;

    setState(() {
      if (!ok) {
        _hasError = true;
        _entry = '';
        _syncTicker();
      } else {
        _entry = '';
        _hasError = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(authControllerProvider);
    final text = Theme.of(context).textTheme;
    final cooling = ctrl.isCoolingDown;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.goalGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.center_focus_strong_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                Text('ConsisApp',
                    style: text.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Ingresa tu PIN de 4 dígitos',
                  style: text.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                PinDots(filled: _entry.length, hasError: _hasError),
                const SizedBox(height: 10),
                SizedBox(
                  height: 20,
                  child: cooling
                      ? Text(
                          'Demasiados intentos · espera '
                          '${ctrl.cooldownRemainingSeconds}s',
                          style: text.bodySmall
                              ?.copyWith(color: AppColors.amber),
                        )
                      : (_hasError
                          ? Text('PIN incorrecto · intenta de nuevo',
                              style:
                                  text.bodySmall?.copyWith(color: AppColors.coral))
                          : null),
                ),
                const SizedBox(height: 14),
                NumericKeypad(
                  onDigit: _onDigit,
                  onDelete: () => setState(() {
                    if (_entry.isNotEmpty) _entry = _entry.substring(0, _entry.length - 1);
                    _hasError = false;
                  }),
                  onBiometric: ctrl.canUseBiometricNow
                      ? () => ctrl.unlockWithBiometric()
                      : null,
                  enabled: !cooling,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
