package com.example.ong.controller;

import com.example.ong.dto.SubmissionDTO;
import com.example.ong.service.EmailService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ong")
@CrossOrigin(origins = "*") // Permitir llamadas desde el frontend (ajusta en producción)
public class OngController {

    private final EmailService emailService;

    public OngController(EmailService emailService) {
        this.emailService = emailService;
    }

    @PostMapping
    public ResponseEntity<?> submit(@Valid @RequestBody SubmissionDTO dto) {
        boolean sent = emailService.sendSubmission(dto);
        if (sent) {
            return ResponseEntity.ok().body(java.util.Map.of("ok", true, "message", "Solicitud recibida y correo enviado (o simulado)."));
        } else {
            return ResponseEntity.status(502).body(java.util.Map.of("ok", false, "error", "No se pudo enviar el correo."));
        }
    }
}
