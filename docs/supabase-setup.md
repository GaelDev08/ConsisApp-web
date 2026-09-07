# CONSIAPP - CONFIGURAR SUPABASE (CUENTA + SINCRONIZACIÓN)

Con esto la app te preguntará "¿Estás registrado?" y sincronizará
tu progreso entre el teléfono y la web.

## PARTE 1 - CREAR EL PROYECTO (2 minutos)
1. Crea cuenta en https://supabase.com (gratis, no pide tarjeta).
2. Botón **New project**.
   - Name: `consisapp`
   - Database password: pon una (guárdala)
   - Region: la más cercana (ej. `South America (sao-paulo)`)
3. Espera a que termine de aprovisionar (~30s).
4. Ve a **SQL Editor → New query**.
   - Pega TODO el contenido de `supabase/schema.sql`
   - Clic **Run** (debería salir "Success. No rows returned").

## PARTE 2 - COPIAR LAS CREDENCIALES
1. En Supabase Dashboard ve a **Settings → API**.
2. Copia:
   - **Project URL** (algo como `https://xxxx.supabase.co`)
   - **anon public key** (empieza con `eyJ...`)
3. Estas dos cosas van por `--dart-define` al compilar (NO en el repo).

## PARTE 3 - COMPILAR CON LAS CREDENCIALES

### Web (Vercel)
```powershell
cd C:\Users\Gaeldev\Desktop\ConsisApp
flutter build web --release `
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```
(subí `build/web` al repo y Vercel lo sirve).

### APK
```powershell
flutter build apk --debug `
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJ...
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

> ⚠️ Si compilas SIN las credenciales, la app sigue funcionando 100% local
> (no pedirá cuenta). Esta es la vía de respaldo.

## PARTE 4 - PRUEBA
1. Abre la app en el teléfono → te aparece "Bienvenido de nuevo".
2. **Regístrate** (correo + contraseña; si pide confirmar correo, hazlo).
3. Crea una meta y registra una sesión.
4. Abre la web (Vercel) → inicia sesión con el MISMO correo →
   verás la misma cuenta (en esta fase ya autentica; los datos se
   sincronizan en la siguiente fase de repos remotos).

## PARTE 5 - CERRAR SESIÓN
- 🔒 Seguridad → "Cerrar sesión". Vuelves a la pantalla de cuenta.

## Notas
- La contraseña no se guarda localmente: solo el token de sesión.
- El PIN sigue actuando como "app lock" local después de la cuenta.