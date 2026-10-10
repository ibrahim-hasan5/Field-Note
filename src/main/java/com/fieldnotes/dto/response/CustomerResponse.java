package com.fieldnotes.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class CustomerResponse {
    private UUID id;
    private String name;
    private String phone;
    private String email;
    private String address;
    private Instant createdAt;
    private Instant updatedAt;
    private Instant deletedAt;
}
