# 🔐 Seguridad híbrida — Configuración Android / iOS

La capa de seguridad (PIN 4 dígitos + biometría + cifrado Hive AES-256) ya está
integrada en el código. Para compilar el **APK móvil** faltan pasos de plataforma:

## 1. Generar las carpetas nativas (una sola vez)

```bash
flutter create --platforms=android,ios .
```

## 2. Android

### 2.1 `android/app/build.gradle.kts` (o `.gradle`)
`local_auth` requiere **minSdk 24**:

```kotlin
defaultConfig {
    // ...
    minSdk = 24   // era flutter.minSdkVersion (21)
}
```

### 2.2 `android/app/src/main/AndroidManifest.xml`
Dentro de `<manifest>` (junto a INTERNET si existe):

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

## 3. iOS (`ios/Runner/Info.plist`) — si compilas para iPhone

```xml
<key>NSFaceIDUsageDescription</key>
<string>Usa Face ID para desbloquear ConsisApp</string>
```

## 4. Comportamiento por plataforma (ya implementado en código)

| Plataforma | Biometría | Flujo |
|------------|-----------|-------|
| Android/iOS | ✅ vía `local_auth` | Auto-prompt al abrir/rebloquear; fallo/cancel → teclado PIN |
| Web (Vercel) | ❌ deshabilitada | Teclado PIN directo (toggle aparece deshabilitado con explicación) |

## 5. ⚠️ Notas sobre el cifrado Hive AES-256

- La clave vive en `flutter_secure_storage` (Keystore/Keychain; en web,
  WebCrypto sobre HTTPS — Vercel ✓).
- **Borrar los datos de la app borra la clave** ⇒ las boxes cifradas quedan
  ilegibles y la app reinicia de cero (comportamiento esperado).
- Si tenías datos previos SIN cifrar (desarrollo Fases 1–3), al habilitar el
  cipher serán ilegibles: limpia IndexedDB del navegador o reinstala.

## 6. Checklist de prueba

1. Primer arranque → crear/confirmar PIN → dashboard.
2. Cerrar y reabrir → LockScreen; escribir mal 5 veces → cooldown 60 s.
3. Activar biometría en 🔒 Seguridad (móvil) → reabrir → prompt automático.
4. Ajustar "Bloqueo automático" a `0s` → background/resume → pide PIN.
5. Cambiar PIN desde Seguridad → verificar que el antiguo ya no funciona.
6. Web: sin botón huella, toggle biométrico deshabilitado con explicación.
