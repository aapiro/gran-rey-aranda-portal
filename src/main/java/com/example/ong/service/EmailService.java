package com.example.ong.service;

import com.example.ong.dto.SubmissionDTO;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Service
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail.to:no-reply@example.org}")
    private String toEmail;

    @Value("${app.mail.from:no-reply@example.org}")
    private String fromEmail;

    @Value("${app.mail.simulate:false}")
    private boolean simulate;

    public EmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    public boolean sendSubmission(SubmissionDTO dto) {
        try {
            String html = buildHtml(dto);

            if (simulate) {
                // Guardar en disco para inspección
                saveSimulatedEmail(html);
                System.out.println("[SIMULATE] Email preparado para: " + toEmail);
                return true;
            }

            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("Nueva solicitud ONG - " + dto.getTipoAyuda() + " - " + dto.getNombre());
            helper.setText(html, true);

            mailSender.send(message);
            System.out.println("Email enviado a: " + toEmail);
            return true;
        } catch (MessagingException mex) {
            System.err.println("Error enviando email: " + mex.getMessage());
            return false;
        } catch (Exception ex) {
            System.err.println("Error interno EmailService: " + ex.getMessage());
            return false;
        }
    }

    private String buildHtml(SubmissionDTO dto) {
        return "<h2>Nueva solicitud - Juntos Transformando Historias</h2>" +
                "<p><strong>Nombre:</strong> " + escape(dto.getNombre()) + "</p>" +
                "<p><strong>Email:</strong> " + escape(dto.getEmail()) + "</p>" +
                "<p><strong>Teléfono:</strong> " + escape(dto.getTelefono()) + "</p>" +
                "<p><strong>Tipo de ayuda:</strong> " + escape(dto.getTipoAyuda()) + "</p>" +
                "<p><strong>Mensaje:</strong><br>" + escape(dto.getMensaje()) + "</p>";
    }

    private String escape(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private void saveSimulatedEmail(String html) {
        try {
            File dir = new File("sent-emails");
            if (!dir.exists()) dir.mkdirs();

            String name = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss")) + "-" + UUID.randomUUID() + ".html";
            File out = new File(dir, name);
            try (FileOutputStream fos = new FileOutputStream(out)) {
                fos.write(html.getBytes(StandardCharsets.UTF_8));
            }
            System.out.println("Simulated email saved: " + out.getAbsolutePath());
        } catch (Exception ex) {
            System.err.println("Error guardando email simulado: " + ex.getMessage());
        }
    }
}

