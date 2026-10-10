package com.fieldnotes.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
public class FieldNoteRequest {
    @NotNull(message = "Site ID is required")
    private UUID siteId;

    @NotBlank(message = "Title is required")
    private String title;

    private String description;
    private Double latitude;
    private Double longitude;

    @NotNull(message = "Note date is required")
    private Instant noteDate;

    @NotBlank(message = "Status is required")
    private String status;
}
