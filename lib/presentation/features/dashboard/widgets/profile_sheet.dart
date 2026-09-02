import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/greeting.dart' show Greeting;
import 'package:consis_app/domain/entities/user_profile.dart';
import 'package:consis_app/presentation/features/dashboard/widgets/sheet_shell.dart';
import 'package:consis_app/presentation/providers/dashboard_providers.dart';
import 'package:consis_app/presentation/providers/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Edición del perfil de usuario: nombre, edad, país y dirección.
Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ProfileSheet(),
  );
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet();

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  bool _seeded = false;
  String? _error;

  String get _initial {
    final n = _nameCtrl.text.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  void _seedFrom(UserProfile p) {
    _nameCtrl.text = p.name;
    _ageCtrl.text = p.age?.toString() ?? '';
    _countryCtrl.text = p.country ?? '';
    _addressCtrl.text = p.address ?? '';
    _seeded = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _countryCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio');
      return;
    }

    final ageRaw = _ageCtrl.text.trim();
    int? age;
    if (ageRaw.isNotEmpty) {
      age = int.tryParse(ageRaw);
      if (age == null || age < 1 || age > 130) {
        setState(() => _error = 'Edad inválida (1–130)');
        return;
      }
    }

    final repo = ref.read(userProfileRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await repo.save(
      UserProfile(
        name: name,
        age: age,
        country:
            _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
        address:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      ),
    );

    navigator.pop();
    messenger.showSnackBar(const SnackBar(
      content: Row(children: [
        Icon(Icons.check_circle_rounded, size: 18, color: AppColors.emerald),
        SizedBox(width: 10),
        Text('Perfil actualizado'),
      ]),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileStreamProvider).valueOrNull;
    if (!_seeded && profile != null) {
      // Semilla única al tener datos cargados (evita pisar edición del usuario).
      _seedFrom(profile);
    } else if (!_seeded) {
      _seeded = true; // sin perfil aún → campos vacíos
    }

    final text = Theme.of(context).textTheme;

    return SheetShell(
      title: 'Mi perfil',
      subtitle: Greeting.forNow(name: _nameCtrl.text),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: AppColors.goalGradient,
                shape: BoxShape.circle,
              ),
              child: Text(_initial,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Tu nombre',
              counterText: '',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _ageCtrl,
                  maxLength: 3,
                  keyboardType: const TextInputType.numberWithOptions(),
                  decoration: const InputDecoration(
                    hintText: 'Edad (opcional)',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _countryCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'País (opcional)',
                    prefixIcon: Icon(Icons.public_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Dirección (opcional)',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: text.bodySmall?.copyWith(color: AppColors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: const Text('Guardar perfil',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

