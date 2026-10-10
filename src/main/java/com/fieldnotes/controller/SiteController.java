package com.fieldnotes.controller;

import com.fieldnotes.dto.request.SiteRequest;
import com.fieldnotes.dto.response.SiteResponse;
import com.fieldnotes.entity.User;
import com.fieldnotes.security.FirebaseUserDetails;
import com.fieldnotes.service.AuthService;
import com.fieldnotes.service.SiteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/sites")
@RequiredArgsConstructor
public class SiteController {

    private final SiteService siteService;
    private final AuthService authService;

    @GetMapping
    public ResponseEntity<List<SiteResponse>> getAll(
            @RequestParam(required = false) UUID customerId,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        if (customerId != null) {
            return ResponseEntity.ok(siteService.getByCustomer(customerId, user));
        }
        return ResponseEntity.ok(siteService.getAll(user));
    }

    @GetMapping("/{id}")
    public ResponseEntity<SiteResponse> getOne(
            @PathVariable UUID id,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(siteService.getOne(id, user));
    }

    @PostMapping
    public ResponseEntity<SiteResponse> create(
            @Valid @RequestBody SiteRequest req,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.status(HttpStatus.CREATED).body(siteService.create(req, user));
    }

    @PutMapping("/{id}")
    public ResponseEntity<SiteResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody SiteRequest req,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(siteService.update(id, req, user));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        siteService.delete(id, user);
        return ResponseEntity.noContent().build();
    }
}
