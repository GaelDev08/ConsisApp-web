# CONSIAPP - DEPLOY EN VERCEL (PASO A PASO)

Guia completa para publicar la app web en Vercel.
El proyecto YA tiene `vercel.json` y `web/index.html` configurados.
Solo falta: 1) generar build/web  2) publicarlo.

## PARTE 0 - PREREQUISITOS
1) Proyecto en tu PC (listo).
2) Cuenta en Vercel (gratis): https://vercel.com
3) [Recomendado] Subir el proyecto a GitHub:
   - git init
   - git add .
   - git commit -m "ConsisApp"
   - git branch -M main
   - git remote add origin https://github.com/TU_USUARIO/ConsisApp.git
   - git push -u origin main
   (El .gitignore ya excluye build/ y .dart_tool/.)

## PARTE 1 - GENERAR EL BUILD WEB
1) Abre PowerShell NORMAL (INICIO -> powershell -> Enter).
   No uses la terminal de VS Code si esta fallando.

2) Entra al proyecto y genera la web:
   cd C:\Users\Gaeldev\Desktop\ConsisApp
   flutter build web --release

3) Resultado correcto:
   C:\Users\Gaeldev\Desktop\ConsisApp\build\web\
   Debe contener: index.html, flutter_bootstrap.js, main.dart.js,
   assets/ y manifest.json.
   (La web NO toca Gradle ni gen_snapshot: no repetira el error del APK.)

## PARTE 2 - DESPLEGAR EN VERCEL (elige UNA opcion)

### OPCION A - CLI vercel (recomendada)
   npm install -g vercel
   cd C:\Users\Gaeldev\Desktop\ConsisApp
   vercel login
   vercel --prod --dir build/web

   En el asistente:
   - "Set up and deploy?" -> Y
   - "In which directory?" -> build/web
   - "Want to modify settings?" -> N
   Resultado: https://consisapp-XXXX.vercel.app

### OPCION B - Dashboard vercel.com
   1) Sube a GitHub (Paso 0).
   2) vercel.com -> New Project -> importa el repo.
   3) Configuracion:
      - Root Directory: build/web   (CLAVE)
      - Framework: Other
      - Build Command: (dejar)
      - Output Directory: (dejar)
   4) Deploy.
   Resultado: https://tu-proyecto.vercel.app

## PARTE 3 - VERIFICAR
1) Abre la URL -> pantalla dark -> "Crea tu PIN" -> dashboard.
2) En web NO hay biometria (por diseno): solo PIN. OK.
3) Recarga: los datos persisten (IndexedDB).
4) Si "404 en rutas internas": vercel.json ya tiene
   rewrite (/(.*) -> /index.html); asegurate de que se subio.
5) Si pantalla gris: F12 -> Console -> pegame el error.