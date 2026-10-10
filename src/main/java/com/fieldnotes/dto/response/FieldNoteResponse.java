package com.fieldnotes.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class FieldNoteResponse {
    private UUID id;
    private String title;
    private String description;
    private Double latitude;
    private Double longitude;
    private Instant noteDate;
    private String status;
    private String photoUrl;
    // Site info (from JOIN)
    private UUID siteId;
    private String siteName;
    // Customer info (from JOIN through site)
    private UUID customerId;
    private String customerName;
    private Instant createdAt;
    private Instant updatedAt;
    private Instant deletedAt;
}
