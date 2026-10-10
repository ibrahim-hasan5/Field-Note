package com.fieldnotes.controller;

import com.fieldnotes.dto.request.FieldNoteRequest;
import com.fieldnotes.dto.response.FieldNoteResponse;
import com.fieldnotes.entity.User;
import com.fieldnotes.security.FirebaseUserDetails;
import com.fieldnotes.service.AuthService;
import com.fieldnotes.service.FieldNoteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/notes")
@RequiredArgsConstructor
public class FieldNoteController {

    private final FieldNoteService fieldNoteService;
    private final AuthService authService;

    @GetMapping
    public ResponseEntity<List<FieldNoteResponse>> getAll(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) UUID siteId,
            @RequestParam(required = false) String q,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(fieldNoteService.getAll(user, status, siteId, q));
    }

    @GetMapping("/{id}")
    public ResponseEntity<FieldNoteResponse> getOne(
            @PathVariable UUID id,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(fieldNoteService.getOne(id, user));
    }

    @PostMapping
    public ResponseEntity<FieldNoteResponse> create(
            @Valid @RequestBody FieldNoteRequest req,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.status(HttpStatus.CREATED).body(fieldNoteService.create(req, user));
    }

    @PutMapping("/{id}")
    public ResponseEntity<FieldNoteResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody FieldNoteRequest req,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(fieldNoteService.update(id, req, user));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        fieldNoteService.delete(id, user);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/photo")
    public ResponseEntity<FieldNoteResponse> uploadPhoto(
            @PathVariable UUID id,
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal FirebaseUserDetails principal) throws IOException {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(fieldNoteService.uploadPhoto(id, user, file));
    }
}
