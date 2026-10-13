package com.fieldnotes.controller;

import com.fieldnotes.dto.request.SyncPushRequest;
import com.fieldnotes.entity.User;
import com.fieldnotes.security.FirebaseUserDetails;
import com.fieldnotes.service.AuthService;
import com.fieldnotes.service.SyncService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

@RestController
@RequestMapping("/api/sync")
@RequiredArgsConstructor
public class SyncController {

    private final SyncService syncService;
    private final AuthService authService;

    /**
     * Pull all changes since a timestamp.
     * If 'since' param is omitted, returns ALL records (used after reinstall).
     *
     * GET /api/sync/pull?since=2024-01-01T00:00:00Z
     */
    @GetMapping("/pull")
    public ResponseEntity<SyncService.SyncPullResponse> pull(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant since,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(syncService.pull(user, since));
    }

    /**
     * Push locally-created/updated records to the server.
     *
     * POST /api/sync/push
     * Body: { customers:[...], sites:[...], notes:[...] }
     */
    @PostMapping("/push")
    public ResponseEntity<SyncService.SyncPushResponse> push(
            @RequestBody SyncPushRequest req,
            @AuthenticationPrincipal FirebaseUserDetails principal) {
        User user = authService.getByFirebaseUid(principal.getUid());
        return ResponseEntity.ok(syncService.push(user, req));
    }
}
