import 'package:consis_app/core/theme/app_colors.dart';
import 'package:consis_app/core/utils/greeting.dart' show Greeting;
import 'package:consis_app/domain/entities/user_profile.dart';
import 'package:consis_app/domain/entities/app_settings.dart';
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
  final TextEditingController _countryCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  
  DateTime? _birthdate;
  ThemeMode? _themeMode;

  bool _seeded = false;
  String? _error;

  String get _initial {
    final n = _nameCtrl.text.trim();
    return n.isEmpty ? '?' : n[0].toUpperCase();
  }

  void _seedFrom(UserProfile p, AppSettings s) {
    _nameCtrl.text = p.name;
    _countryCtrl.text = p.country ?? '';
    _addressCtrl.text = p.address ?? '';
    _birthdate = p.birthdate;
    _themeMode = s.themeMode;
    _seeded = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
    );
    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'El nombre es obligatorio');
      return;
    }

    final repo = ref.read(userProfileRepositoryProvider);
    final settingsRepo = ref.read(appSettingsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await repo.save(
      UserProfile(
        name: name,
        birthdate: _birthdate,
        country:
            _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
        address:
            _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      ),
    );

    if (_themeMode != null) {
      final currentSettings = await settingsRepo.load();
      await settingsRepo.save(currentSettings.copyWith(themeMode: _themeMode));
    }

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
    final settings = ref.watch(appSettingsStreamProvider).valueOrNull;
    
    if (!_seeded && profile != null && settings != null) {
      _seedFrom(profile, settings);
    } else if (!_seeded) {
      _seeded = true;
    }

    final text = Theme.of(context).textTheme;

    return SheetShell(
      title: 'Configuración / Perfil',
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
                child: GestureDetector(
                  onTap: _pickBirthdate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _birthdate != null
                          ? '\${_birthdate!.day}/\${_birthdate!.month}/\${_birthdate!.year}'
                          : 'Nacimiento',
                      style: text.bodyLarge?.copyWith(
                        color: _birthdate != null ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
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
          const SizedBox(height: 24),
          Text('Tema de la Aplicación', style: text.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
              ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode)),
              ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.settings_suggest)),
            ],
            selected: {_themeMode ?? ThemeMode.system},
            onSelectionChanged: (set) {
              setState(() => _themeMode = set.first);
            },
            showSelectedIcon: false,
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
            child: const Text('Guardar configuración',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

