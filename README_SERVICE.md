Microservicio ONG - Envío de formulario por Gmail

Resumen
-------
Microservicio Spring Boot que expone POST /api/ong para recibir el formulario "Juntos Transformando Historias" y enviar los datos por correo usando Gmail (SMTP). Incluye modo simulación (por defecto) para desarrollo.

Variables de entorno
--------------------
 - MAIL_USERNAME: cuenta de Gmail (ej: ejemplo@gmail.com)
 - MAIL_PASSWORD: contraseña de aplicación (app password) o token
 - MAIL_FROM: email desde (opcional)
 - MAIL_TO: email que recibirá las solicitudes
 - EMAIL_SIMULATE: true|false (por defecto true — simula envío escribiendo archivos en sent-emails/)
 - SERVER_PORT: puerto (opcional)

Build y ejecución local
-----------------------
1) Build:

   mvn -DskipTests clean package

2) Ejecutar (en PowerShell temporalmente):

   $env:MAIL_USERNAME="tu@gmail.com"; $env:MAIL_PASSWORD="appPassword"; $env:EMAIL_SIMULATE="false"; java -jar target/ong-email-service-0.0.1-SNAPSHOT.jar

Docker
------
1) Build (asegúrate de haber generado el jar):

   docker build -t ong-email-service:latest .

2) Run:

   docker run -e MAIL_USERNAME=... -e MAIL_PASSWORD=... -e MAIL_FROM=... -e MAIL_TO=... -p 8080:8080 ong-email-service:latest

Endpoint
--------
POST /api/ong
Content-Type: application/json
Body ejemplo:

{
  "nombre": "María López",
  "email": "maria@example.com",
  "telefono": "+34123456789",
  "tipoAyuda": "donacion",
  "mensaje": "Quiero apoyar con una donación mensual."
}

Respuesta (200):
{ "ok": true, "message": "Solicitud recibida y correo enviado (o simulado)." }

Notas
-----
 - Por simplicidad usamos App Passwords para Gmail. Para producción considere OAuth2 o servicios de correo dedicados.
 - No suba variables sensibles al repositorio.

