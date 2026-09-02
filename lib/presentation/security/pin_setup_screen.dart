import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/domain/entities/user_profile.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:consis_app/presentation/providers/security_providers.dart';
import 'package:consis_app/presentation/security/widgets/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Primer arranque: creación/confirmación del PIN + nombre de usuario.
enum _SetupPhase { create, confirm, name }

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  _SetupPhase _phase = _SetupPhase.create;
  String _entry = '';
  String _tempPin = '';
  bool _hasError = false;
  final TextEditingController _nameCtrl = TextEditingController();

  bool get _isName => _phase == _SetupPhase.name;

  String get _title {
    switch (_phase) {
      case _SetupPhase.create:
        return 'Crea tu PIN';
      case _SetupPhase.confirm:
        return 'Confirma tu PIN';
      case _SetupPhase.name:
        return '¿Cómo te llamas?';
    }
  }

  String get _subtitle {
    switch (_phase) {
      case _SetupPhase.create:
        return '4 dígitos · se pedirán cada vez que abras la app';
      case _SetupPhase.confirm:
        return 'Repite los mismos 4 dígitos';
      case _SetupPhase.name:
        return 'Para saludarte como te mereces';
    }
  }

  IconData get _headerIcon =>
      _isName ? Icons.person_rounded : Icons.lock_rounded;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _resetToCreate({String? error}) {
    setState(() {
      _phase = _SetupPhase.create;
      _entry = '';
      _tempPin = '';
      _hasError = error != null;
    });
  }

  void _onDigit(String digit) {
    if (_entry.length >= 4) return;
    setState(() {
      _entry += digit;
      _hasError = false;
    });
    if (_entry.length == 4) {
      Future.delayed(const Duration(milliseconds: 160), _advance);
    }
  }

  Future<void> _advance() async {
    if (_phase == _SetupPhase.create) {
      setState(() {
        _tempPin = _entry;
        _phase = _SetupPhase.confirm;
        _entry = '';
      });
      return;
    }

    if (_phase == _SetupPhase.confirm) {
      if (_entry == _tempPin) {
        setState(() {
          _phase = _SetupPhase.name;
          _entry = '';
          _hasError = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _entry = '';
          _phase = _SetupPhase.create;
        });
      }
    }
  }

  Future<void> _confirmName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    await ref
        .read(userProfileRepositoryProvider)
        .save(UserProfile(name: name));
    await ref.read(authControllerProvider).setupPin(_tempPin);
    // AuthGate reacciona al cambio de estado y entra al dashboard.
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

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
                  child: Icon(_headerIcon, color: Colors.white, size: 34),
                ),
                const SizedBox(height: 20),
                if (_phase != _SetupPhase.create)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => _phase == _SetupPhase.name
                          ? _resetToCreate()
                          : setState(() {
                              _phase = _SetupPhase.create;
                              _entry = '';
                            }),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textSecondary,
                    ),
                  ),
                Text(_title,
                    style:
                        text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(_subtitle,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 28),
                if (_isName) ...[
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    maxLength: 30,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {
                      if (_hasError) setState(() => _hasError = false);
                    },
                    decoration: InputDecoration(
                      hintText: 'Tu nombre',
                      counterText: '',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      errorText: _hasError
                          ? 'Escribe tu nombre para continuar'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _confirmName,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: const Text('Continuar',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ] else ...[
                  PinDots(filled: _entry.length, hasError: _hasError),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 20,
                    child: _hasError
                        ? Text('No coincide con el PIN creado',
                            style: text.bodySmall
                                ?.copyWith(color: AppColors.coral))
                        : null,
                  ),
                  const SizedBox(height: 14),
                  NumericKeypad(
                    onDigit: _onDigit,
                    onDelete: () => setState(() {
                      if (_entry.isNotEmpty) {
                        _entry = _entry.substring(0, _entry.length - 1);
                      }
                      _hasError = false;
                    }),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
