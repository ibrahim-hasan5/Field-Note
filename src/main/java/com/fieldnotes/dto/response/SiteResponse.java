package com.fieldnotes.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class SiteResponse {
    private UUID id;
    private String name;
    private String address;
    private UUID customerId;
    private String customerName;
    private Instant createdAt;
    private Instant updatedAt;
    private Instant deletedAt;
}
