# ConsisApp - GUIA PASO A PASO (APK + Vercel)

## IMPORTANTE
La consola de VS Code te da error. **NO la uses.** Usa una
**PowerShell normal de Windows**. Forma mas rapida:

1. Pulsa la tecla **Windows** (o clic en el menu inicio).
2. Escribe `powershell` y pulsa **Enter** (o "Run as Administrator").
3. Copia y pega cada bloque de abajo.

---

## PARTE 1 - CONSTRUIR EL APK

Ejecuta en PowerShell (una linea a la vez):

```powershell
cd C:\Users\Gaeldev\Desktop\ConsisApp
powershell -ExecutionPolicy Bypass -File .\build_all.ps1
```

`build_all.ps1` hace: pub get -> build web -> build apk.
(Este ultimo tarda 3-8 min la primera vez.)

Al terminar veras la linea verde:
```
[OK] APK  : C:\...\build\app\outputs\flutter-apk\app-release.apk  (XX MB)
```

### Si el APK falla con:  gradle-fileevents.dll ... "No se encontró el proceso especificado"
Esto significa que falta el **Visual C++ Redistributable** de Windows.

**Paso obligatorio (solo una vez):**
1. Descargar e instalar: https://aka.ms/vs/17/release/vc_redist.x64.exe
2. **REINICIAR la maquina.**
3. Borrar la cache rota y reintentar:
```powershell
Remove-Item "$env:USERPROFILE\.gradle\native" -Recurse -Force
powershell -ExecutionPolicy Bypass -File .\build_all.ps1
```

---

## PARTE 2 - INSTALAR EL APK EN TU TELEFONO

1. En el telefono: **Ajustes -> Acerca del telefono -> Toca 7 veces "N�"** para activar
   "Opciones de programador".
2. Entra en **Opciones de programador -> activa "Depuración USB"**.
3. Conecta el telefono por USB y acepta el permiso.
4. Verifica que se ve:
```powershell
adb devices
```
5. Instala:
```powershell
adb install -r C:\Users\Gaeldev\Desktop\ConsisApp\build\app\outputs\flutter-apk\app-release.apk
```

Si no quieres usar USB: copia el `.apk` a tu lista/Drive y en el telefono quedras
"Instalar por ADB" o "Abrir con instalador" (hay que permitir fuentes desconocidas).

---

## PARTE 3 - DESPLEGAR EN VERCEL (WEB)

1. El `build_all.ps1` ya genero la web en:
```
C:\Users\Gaelved\Desktop\ConsisApp\build\web\
```
2. Sube tu proyecto a **GitHub** (si aun no): crea un repo, sube todo (excepto carpetas
   `build/`, `.dart_tool/`, etc.).
3. Entra a **vercel.com** -> **New Project** -> importa tu repo.
4. En la config del proyecto:
   - **Root Directory**: `build/web`
   - Framework: Other
   - Build Command: (vacío)
   - Output Directory: (vacío /verdadero)
5. Deploy. Te da una URL tipo `https://tu-app-<nombre>.vercel.app`.

### Alternativa SOLO con archivos (sin Vercel CLI):
- El `vercel.json` del proyecto ya tiene `outputDirectory: "build/web"` y el rewrite SPA.
- Es decir, tu build local se sirve tal cual.

---

## RESUMEN DE COMANDOS CLAVES (copiar/pegar)

```powershell
cd C:\Users\Gaeldev\Desktop\ConsisApp
powershell -ExecutionPolicy Bypass -File .\build_all.ps1
```

Si falla el APK (DLL):
```powershell
Remove-Item "$env:USERPROFILE\.gradle\native" -Recurse -Force
powershell -ExecutionPolicy Bypass -File .\build_all.ps1
```

Instalar:
```powershell
adb install -r .\build\app\outputs\flutter-apk\app-release.apk
```
```