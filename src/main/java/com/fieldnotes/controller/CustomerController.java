package com.fieldnotes.controller;

import com.fieldnotes.dto.request.CustomerRequest;
import com.fieldnotes.dto.response.CustomerResponse;
import com.fieldnotes.entity.User;
import com.fieldnotes.security.FirebaseUserDetails;
import com.fieldnotes.service.AuthService;
import com.fieldnotes.service.CustomerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/customers")
@RequiredArgsConstructor
public class CustomerController {

    private final CustomerService customerService;
    private final AuthService authService;

    @GetMapping
    public ResponseEntity<List<CustomerResponse>> getAll(
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(customerService.getAll(user));
    }

    @GetMapping("/{id}")
    public ResponseEntity<CustomerResponse> getOne(
            @PathVariable UUID id,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(customerService.getOne(id, user));
    }

    @PostMapping
    public ResponseEntity<CustomerResponse> create(
            @Valid @RequestBody CustomerRequest req,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.status(HttpStatus.CREATED).body(customerService.create(req, user));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CustomerResponse> update(
            @PathVariable UUID id,
            @Valid @RequestBody CustomerRequest req,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(customerService.update(id, req, user));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        customerService.delete(id, user);
        return ResponseEntity.noContent().build();
    }
}
