# Proyecto: Ministerio Gran Rey — Portal

Este repo contiene una landing estática (HTML/CSS/JS) y dos implementaciones de backend para recibir y procesar el formulario "Juntos Transformando Historias":

- `ministerio-gran-rey-final.html`: página pública (frontend) con el formulario de la ONG.
- `server.js` + `package.json`: un backend Node.js/Express mínimo (ejemplo) que recibe POST `/api/ong` y envía correo mediante Gmail (usa `nodemailer`). Incluye modo simulación si no hay credenciales.
- `src/...` (Spring Boot): implementación de un microservicio Java (Maven) que expone `POST /api/ong`, valida la entrada y envía correo mediante `spring-boot-starter-mail` (también con modo simulación por defecto).
- `tools/setup-jdk.ps1`: helper PowerShell para configurar una JDK portable o usar JBR (IntelliJ) y ejecutar el JAR localmente sin instalar Java en el sistema.

Objetivo
--------
Permitir que las solicitudes del formulario "Juntos Transformando Historias" lleguen a un servicio que las envíe por correo (Gmail SMTP). Para desarrollo el envío está en modo simulación por defecto para evitar requerir credenciales de correo.

Estructura principal
--------------------
- `ministerio-gran-rey-final.html` — frontend estático (formulario + lógica JS para enviar datos a `/api/ong`).
- `server.js` — ejemplo de backend Node.js (Express + nodemailer) con modo simulación.
- `package.json` — dependencias Node (express, nodemailer, dotenv, cors).
- `pom.xml` — proyecto Maven para el microservicio Java.
- `src/main/java/com/example/ong/` — código Spring Boot (controller, DTO, service, exception handler).
- `src/main/resources/application.properties` — configuración del microservicio Java.
- `Dockerfile` — imagen runtime Java para el microservicio.
- `tools/setup-jdk.ps1` — script PowerShell para preparar JDK portable si no tienes Java instalado.
- `.env.example` — ejemplo de variables de entorno para Node.js backend.
- `README_SERVICE.md` — instrucciones específicas del microservicio Java (build/run/Docker).
- `README_EMAIL.md` — instrucciones rápidas del backend Node.js (enviar correo con Gmail).

Contratos y comportamiento del endpoint
---------------------------------------
Endpoint: POST /api/ong
- Content-Type: application/json
- Body esperado (ejemplo):
  {
    "nombre": "María López",
    "email": "maria@example.com",
    "telefono": "+34123456789",
    "tipoAyuda": "donacion",
    "mensaje": "Quiero apoyar con una donación mensual."
  }
Respuestas:
- 200 OK → { "ok": true, "message": "Solicitud recibida y correo enviado (o simulado)." }
- 400 Bad Request → { "ok": false, "errors": { campo: mensaje } }
- 500/502 → { "ok": false, "error": "..." }

Modos de ejecución
------------------
1) Node.js (opcional — ejemplo rápido)

Requisitos: Node.js y npm instalados.

- Instalar dependencias:

```powershell
npm install
```

- Crear `.env` a partir de `.env.example` y completar `GMAIL_USER`, `GMAIL_PASS`, `TO_EMAIL`.

- Ejecutar servidor:

```powershell
npm start
```

El servidor servirá archivos estáticos desde la raíz del proyecto y expondrá `POST /api/ong`.

2) Java Spring Boot (microservicio recomendado para despliegue)

Requisitos: Java 17 y Maven. Si no tienes Java, puedes usar `tools/setup-jdk.ps1` para descargar/usar una JDK portable o usar JBR de IntelliJ.

- Compilar:

```powershell
mvn -DskipTests clean package
```

- Ejecutar JAR (PowerShell):

```powershell
$env:MAIL_USERNAME="tu@gmail.com"
$env:MAIL_PASSWORD="tu-app-password"
$env:MAIL_FROM="no-reply@ministeriogranrey.org"
$env:MAIL_TO="destino@ministeriogranrey.org"
$env:EMAIL_SIMULATE="false"  # poner false para envío real
java -jar target/ong-email-service-0.0.1-SNAPSHOT.jar
```

Si `EMAIL_SIMULATE` está en `true` (valor por defecto en `application.properties`), no se envía el correo y el HTML del email se guarda en `sent-emails/`.

3) Usar JDK portable (si no tienes Java)

Desde PowerShell en la raíz del repo:

```powershell
# buscar/usar JBR de IntelliJ
.\tools\setup-jdk.ps1 -UseIntelliJ -JarToRun "target\ong-email-service-0.0.1-SNAPSHOT.jar"

# o descargar Temurin 17 y ejecutar
.\tools\setup-jdk.ps1 -JarToRun "target\ong-email-service-0.0.1-SNAPSHOT.jar"
```

Docker
------
- Construir imagen (asegúrate primero de generar el jar con `mvn package`):

```powershell
docker build -t ong-email-service:latest .
```

- Ejecutar contenedor con variables de entorno:

```powershell
docker run -e MAIL_USERNAME=tu@gmail.com -e MAIL_PASSWORD=appPassword -e MAIL_FROM=no-reply@... -e MAIL_TO=destino@... -e EMAIL_SIMULATE=false -p 8080:8080 ong-email-service:latest
```

Frontend: integración
---------------------
- El formulario en `ministerio-gran-rey-final.html` está configurado para hacer POST JSON a `/api/ong` (ruta relativa). Si sirves el frontend desde otro origen, cambia la URL en el `fetch` del archivo JS a la URL completa del microservicio (por ejemplo `http://localhost:8080/api/ong`).
- El microservicio Java permite CORS desde cualquier origen (`@CrossOrigin(origins = "*")`) para facilitar pruebas. En producción restringe los orígenes.

Variables de entorno y seguridad
-------------------------------
- No subas credenciales al repositorio.
- Para Gmail en producción utiliza App Passwords (si tu cuenta tiene 2FA) o implementa OAuth2 en lugar de almacenar contraseñas.
- Variables relevantes (Java): `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM`, `MAIL_TO`, `EMAIL_SIMULATE`.
- Variables relevantes (Node): revisar `.env.example`.

Archivos que te pueden interesar
-------------------------------
- `ministerio-gran-rey-final.html` — frontend y lógica del formulario
- `server.js` — backend Node ejemplo
- `.env.example` — plantilla para Node
- `pom.xml` — Maven
- `src/` — código Java (controller, DTO, service)
- `tools/setup-jdk.ps1` — helper JDK portable

Pruebas rápidas
---------------
- Con el servicio Java corriendo en `localhost:8080`:

```powershell
curl -v -X POST http://localhost:8080/api/ong -H "Content-Type: application/json" -d '{"nombre":"María","email":"maria@example.com","telefono":"+34123456789","tipoAyuda":"donacion","mensaje":"Me gustaría ayudar."}'
```

Soporte y mejoras posibles
--------------------------
- Añadir soporte para archivos adjuntos (`multipart/form-data`) si queréis adjuntar documentos.
- Guardar envíos en una base de datos para auditoría.
- Implementar autenticación (API key) o rate limiting para evitar abuso.
- Cambiar a OAuth2 para Gmail o usar un proveedor de correo profesional (SendGrid, Mailgun) en producción.

Licencia
--------
Este proyecto es una plantilla y ejemplo. Asegúrate de revisar y adaptar las configuraciones de seguridad antes de desplegar en producción.

