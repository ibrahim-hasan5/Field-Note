package com.fieldnotes.dto.request;

import lombok.Data;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Payload sent by the Flutter client to push locally-created/updated records
 * to the server in a single batch call.
 */
@Data
public class SyncPushRequest {

    private List<PushCustomer> customers;
    private List<PushSite>     sites;
    private List<PushNote>     notes;

    /* ── Nested record DTOs ── */

    @Data
    public static class PushCustomer {
        private UUID   id;          // client-generated UUID
        private String name;
        private String phone;
        private String email;
        private String address;
        private Instant deletedAt;  // non-null ⇒ soft-delete
    }

    @Data
    public static class PushSite {
        private UUID   id;
        private UUID   customerId;
        private String name;
        private String address;
        private Instant deletedAt;
    }

    @Data
    public static class PushNote {
        private UUID    id;
        private UUID    siteId;
        private String  title;
        private String  description;
        private Double  latitude;
        private Double  longitude;
        private Instant noteDate;
        private String  status;
        private Instant deletedAt;
    }
}
