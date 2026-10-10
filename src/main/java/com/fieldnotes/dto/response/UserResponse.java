package com.fieldnotes.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class UserResponse {
    private UUID id;
    private String firebaseUid;
    private String email;
    private String displayName;
    private Instant createdAt;
}
