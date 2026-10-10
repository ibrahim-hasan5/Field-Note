package com.fieldnotes.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class SiteRequest {
    @NotBlank(message = "Site name is required")
    private String name;

    private String address;

    @NotNull(message = "Customer ID is required")
    private UUID customerId;
}
