Portable JDK helper

Este repositorio incluye un helper PowerShell `tools/setup-jdk.ps1` para facilitar pruebas en entornos Windows donde no haya Java instalado.

Funciones principales:
 - Detecta si `java` ya está en PATH. Si existe, muestra la versión y puede ejecutar un JAR.
 - Busca JBR/JetBrains Runtime en instalaciones de IntelliJ y, si lo encuentra, lo añade al PATH temporalmente.
 - Si no hay JDK, puede descargar Temurin JDK 17 (build por Adoptium) y extraerlo en `.jdk/` dentro del repo.
 - Ajusta `JAVA_HOME` y `PATH` para la sesión actual; no modifica variables de entorno permanentes.

Uso rápido (desde la raíz del proyecto, PowerShell):

1) Si ya tienes Java en el sistema:
   .\tools\setup-jdk.ps1

2) Forzar búsqueda de IntelliJ JBR:
   .\tools\setup-jdk.ps1 -UseIntelliJ

3) Descargar automáticamente Temurin JDK 17 y extraer en `.jdk`:
   .\tools\setup-jdk.ps1

4) Ejecutar el JAR del servicio tras configurar el JDK (ejemplo):
   .\tools\setup-jdk.ps1 -JarToRun "target\ong-email-service-0.0.1-SNAPSHOT.jar"

Nota: el script pregunta confirmación antes de descargar. Puedes pasar `-JdkUrl` para usar una URL concreta y `-Force` para sobreescribir carpetas existentes.

