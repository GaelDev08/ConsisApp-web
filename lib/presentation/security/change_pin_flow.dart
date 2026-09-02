import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/presentation/providers/security_providers.dart';
import 'package:consis_app/presentation/security/widgets/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flujo "Cambiar PIN": verifica actual → nuevo → confirmación.
///
/// Es un widget de contenido (sin Scaffold): lo hospeda el sheet de
/// Seguridad dentro de su propio shell.
enum _Step { current, createNew, confirmNew }

class ChangePinFlow extends ConsumerStatefulWidget {
  /// Vuelve al menú del sheet de Seguridad sin cerrarlo.
  final VoidCallback? onBackToMenu;

  const ChangePinFlow({super.key, this.onBackToMenu});

  @override
  ConsumerState<ChangePinFlow> createState() => _ChangePinFlowState();
}

class _ChangePinFlowState extends ConsumerState<ChangePinFlow> {
  _Step _step = _Step.current;
  String _entry = '';
  String _verifiedOld = '';
  String _newPin = '';
  String? _error;

  String get _title {
    switch (_step) {
      case _Step.current:
        return 'Ingresa tu PIN actual';
      case _Step.createNew:
        return 'Nuevo PIN';
      case _Step.confirmNew:
        return 'Confirma el nuevo PIN';
    }
  }

  void _onDigit(String digit) {
    if (_entry.length >= 4) return;
    setState(() {
      _entry += digit;
      _error = null;
    });
    if (_entry.length == 4) {
      Future.delayed(const Duration(milliseconds: 140), _advance);
    }
  }

  Future<void> _advance() async {
    final ctrl = ref.read(authControllerProvider);

    switch (_step) {
      case _Step.current:
        final ok = await ctrl.verifyPin(_entry);
        if (!mounted) return;
        setState(() {
          if (!ok) {
            _error = 'PIN actual incorrecto';
            _entry = '';
          } else {
            _verifiedOld = _entry;
            _entry = '';
            _step = _Step.createNew;
          }
        });

      case _Step.createNew:
        if (_entry == _verifiedOld) {
          setState(() {
            _error = 'Debe ser distinto al PIN actual';
            _entry = '';
          });
          return;
        }
        setState(() {
          _newPin = _entry;
          _entry = '';
          _step = _Step.confirmNew;
        });

      case _Step.confirmNew:
        if (_entry != _newPin) {
          setState(() {
            _error = 'No coincide · repite el nuevo PIN';
            _entry = '';
            _step = _Step.createNew;
          });
          return;
        }

        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        await ctrl.changePin(_newPin);

        navigator.pop();
        messenger.showSnackBar(const SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_rounded, size: 18, color: AppColors.emerald),
            SizedBox(width: 10),
            Text('PIN actualizado'),
          ]),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _step = _Step.current;
                  _entry = '';
                  _error = null;
                });
                widget.onBackToMenu?.call();
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              color: AppColors.textSecondary,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Text(_title,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        PinDots(filled: _entry.length, hasError: _error != null),
        const SizedBox(height: 8),
        SizedBox(
          height: 18,
          child: _error != null
              ? Text(_error!,
                  style: text.bodySmall?.copyWith(color: AppColors.coral))
              : null,
        ),
        const SizedBox(height: 10),
        NumericKeypad(
          onDigit: _onDigit,
          onDelete: () => setState(() {
            if (_entry.isNotEmpty) {
              _entry = _entry.substring(0, _entry.length - 1);
            }
            _error = null;
          }),
        ),
      ],
    );
  }
}
