package com.fieldnotes.controller;

import com.fieldnotes.dto.response.UserResponse;
import com.fieldnotes.security.FirebaseUserDetails;
import com.fieldnotes.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * Called by Flutter after Firebase sign-in to register/update user in our DB.
     * Idempotent — safe to call on every login.
     */
    @PostMapping("/register")
    public ResponseEntity<UserResponse> register(
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        return ResponseEntity.ok(authService.registerOrUpdate(principal));
    }

    @GetMapping("/me")
    public ResponseEntity<UserResponse> me(
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        return ResponseEntity.ok(authService.getCurrentUser(principal));
    }
}
