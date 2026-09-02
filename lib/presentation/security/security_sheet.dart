import 'package:consis_app/core/security/auth_controller.dart';
import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/profile_sheet.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/security_providers.dart';
import 'package:consis_app/presentation/security/change_pin_flow.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Panel de seguridad accesible desde el dashboard:
/// biometría, timeout de rebloqueo, cambio de PIN y bloqueo manual.
Future<void> showSecuritySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _SecuritySheet(),
  );
}

enum _SecurityView { menu, changePin }

class _SecuritySheet extends ConsumerStatefulWidget {
  const _SecuritySheet();

  @override
  ConsumerState<_SecuritySheet> createState() => _SecuritySheetState();
}

class _SecuritySheetState extends ConsumerState<_SecuritySheet> {
  _SecurityView _view = _SecurityView.menu;

  String get _biometricSubtitle {
    if (kIsWeb) return 'No disponible en navegador · usa tu PIN';
    final hasHardware = ref.read(authControllerProvider).hasBiometrics;
    if (!hasHardware) return 'Sin biometría configurada en este dispositivo';
    return 'Huella / Face ID al abrir la app';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(authControllerProvider);
    final text = Theme.of(context).textTheme;

    final Widget content = switch (_view) {
      _SecurityView.menu => _buildMenu(context, ctrl, text),
      _SecurityView.changePin => ChangePinFlow(
          onBackToMenu: () => setState(() => _view = _SecurityView.menu),
        ),
    };

    return SheetShell(
      title: 'Seguridad',
      subtitle: _view == _SecurityView.menu
          ? 'PIN + cifrado AES protegen tus datos'
          : null,
      child: content,
    );
  }

  Widget _buildMenu(BuildContext context, AuthController ctrl, TextTheme text) {
    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    final profileName = (profile?.hasName ?? false) ? profile!.name : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          value: ctrl.biometricEnabled,
          onChanged: ctrl.hasBiometrics
              ? (value) => ref.read(authControllerProvider).setBiometricEnabled(value)
              : null,
          secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.cyan),
          title: const Text('Desbloqueo biométrico'),
          subtitle: Text(_biometricSubtitle, style: text.bodySmall),
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        Text('Bloqueo automático al regresar',
            style: text.labelMedium?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('0s')),
            ButtonSegment(value: 15, label: Text('15s')),
            ButtonSegment(value: 30, label: Text('30s')),
            ButtonSegment(value: 60, label: Text('60s')),
          ],
          selected: {ctrl.lockTimeoutSeconds},
          onSelectionChanged: (selection) =>
              ref.read(authControllerProvider).setLockTimeout(selection.first),
        ),
        const Divider(height: 28),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.person_outline_rounded,
              color: AppColors.violet),
          title: const Text('Mi perfil'),
          subtitle: Text(profileName ?? 'Sin configurar',
              style: text.bodySmall),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted),
          onTap: () => showProfileSheet(context),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.key_rounded, color: AppColors.violet),
          title: const Text('Cambiar PIN'),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted),
          onTap: () => setState(() => _view = _SecurityView.changePin),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline_rounded, color: AppColors.amber),
          title: const Text('Bloquear ahora'),
          onTap: () {
            final navigator = Navigator.of(context);
            ref.read(authControllerProvider).lockNow();
            navigator.pop();
          },
        ),
      ],
    );
  }
}
