# ConsisApp 🎯

**Hiperenfoque y consistencia.** Un solo objetivo principal activo a la vez (ej. *200 min de ejercicio/semana*), control de peso semanal con día configurable, semáforo nutricional diario (🟢🟡🔴) y bitácora de fricciones ("¿Por qué no cumplí?").

## Stack

| Capa | Tecnología |
|------|------------|
| UI | Flutter (Material 3, Dark Mode Premium) |
| Estado | Riverpod |
| Persistencia | **hive_ce / hive_ce_flutter** (IndexedDB en Web, archivos en móvil) |
| Gráficos/Calendario | fl_chart · table_calendar (Fases 2–4) |
| Deploy | Flutter Web → Vercel (SPA rewrite) |

## Arquitectura

```
lib/
├── core/           # Tema, constantes (presets de fricción), utilidades de fecha
├── data/
│   ├── local/      # hive_registry (box names/typeIds) + hive_manager (bootstrap)
│   └── models/     # 5 modelos Hive con TypeAdapters manuales (sin build_runner)
├── domain/
│   ├── entities/   # Entidades puras e inmutables (+ AppSettings con día de pesaje)
│   └── repositories/ # Contratos abstractos
└── presentation/
    ├── app/        # MaterialApp + tema
    └── home/       # Placeholder (Fase 2: dashboard responsive)
```

## Comandos

```bash
flutter pub get                 # dependencias

# (Opcional) Agregar plataformas móviles al proyecto existente:
flutter create --platforms=android,ios .

# Desarrollo
flutter run -d chrome           # web
flutter analyze                 # lints

# Build para Vercel
flutter build web --release     # salida: build/web/
```

## Deploy en Vercel

El `vercel.json` ya está configurado:

- `outputDirectory: build/web`
- Rewrite SPA `/(.*) → /index.html` (evita 404 al recargar rutas)
- Cacheo immutable para `/assets/*`, `no-cache` para `index.html` y service worker

Dos formas de desplegar:

1. **Local:** `flutter build web --release && vercel --prod` (Vercel sirve `build/web`).
2. **CI (GitHub Actions):** build con `subosito/flutter-action` y deploy del folder `build/web`.

> Nota PWA: `web/manifest.json` está incluido sin íconos binarios; agrega los íconos 192/512 cuando tengas los assets de marca.
