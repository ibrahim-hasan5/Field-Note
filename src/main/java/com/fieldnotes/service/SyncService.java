package com.fieldnotes.service;

import com.fieldnotes.dto.request.SyncPushRequest;
import com.fieldnotes.dto.request.SyncPushRequest.*;
import com.fieldnotes.dto.response.CustomerResponse;
import com.fieldnotes.dto.response.FieldNoteResponse;
import com.fieldnotes.dto.response.SiteResponse;
import com.fieldnotes.entity.Customer;
import com.fieldnotes.entity.FieldNote;
import com.fieldnotes.entity.Site;
import com.fieldnotes.entity.User;
import com.fieldnotes.repository.CustomerRepository;
import com.fieldnotes.repository.FieldNoteRepository;
import com.fieldnotes.repository.SiteRepository;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class SyncService {

    private final CustomerRepository customerRepository;
    private final SiteRepository siteRepository;
    private final FieldNoteRepository fieldNoteRepository;
    private final CustomerService customerService;
    private final SiteService siteService;
    private final FieldNoteService fieldNoteService;

    /**
     * Pull all changes since a timestamp.
     * If 'since' is null, returns ALL records (initial full pull / post-reinstall restore).
     */
    public SyncPullResponse pull(User user, Instant since) {
        List<CustomerResponse> customers;
        List<SiteResponse> sites;
        List<FieldNoteResponse> notes;

        if (since == null) {
            // Full pull — restore everything
            customers = customerRepository.findAllByUserId(user.getId())
                    .stream().map(customerService::toResponse).toList();
            sites = siteRepository.findAllByUserId(user.getId())
                    .stream().map(siteService::toResponse).toList();
            notes = fieldNoteRepository.findAllByUserId(user.getId())
                    .stream().map(fieldNoteService::toResponse).toList();
        } else {
            // Delta pull — only changes since timestamp
            customers = customerRepository.findByUserIdAndUpdatedAtAfter(user.getId(), since)
                    .stream().map(customerService::toResponse).toList();
            sites = siteRepository.findByUserIdAndUpdatedAtAfter(user.getId(), since)
                    .stream().map(siteService::toResponse).toList();
            notes = fieldNoteRepository.findByUserIdAndUpdatedAtAfter(user.getId(), since)
                    .stream().map(fieldNoteService::toResponse).toList();
        }

        return SyncPullResponse.builder()
                .customers(customers)
                .sites(sites)
                .notes(notes)
                .pulledAt(Instant.now())
                .build();
    }

    /**
     * Push locally-created/updated records from the client.
     * Uses upsert semantics: if a record with that client UUID already exists on the
     * server it is updated, otherwise it is inserted.
     */
    @Transactional
    public SyncPushResponse push(User user, SyncPushRequest req) {
        int customersUpserted = 0, sitesUpserted = 0, notesUpserted = 0;
        List<String> errors = new ArrayList<>();

        // ── Customers ───────────────────────────────────────────────────
        if (req.getCustomers() != null) {
            for (PushCustomer pc : req.getCustomers()) {
                try {
                    Optional<Customer> existing = customerRepository.findByIdAndUserId(pc.getId(), user.getId());
                    Customer c;
                    if (existing.isPresent()) {
                        c = existing.get();
                    } else {
                        c = new Customer();
                        c.setId(pc.getId());
                        c.setUser(user);
                    }
                    c.setName(pc.getName());
                    c.setPhone(pc.getPhone());
                    c.setEmail(pc.getEmail());
                    c.setAddress(pc.getAddress());
                    if (pc.getDeletedAt() != null) c.setDeletedAt(pc.getDeletedAt());
                    customerRepository.save(c);
                    customersUpserted++;
                } catch (Exception e) {
                    errors.add("customer:" + pc.getId() + " – " + e.getMessage());
                }
            }
        }

        // ── Sites ────────────────────────────────────────────────────────
        if (req.getSites() != null) {
            for (PushSite ps : req.getSites()) {
                try {
                    Optional<Site> existing = siteRepository.findByIdAndUserId(ps.getId(), user.getId());
                    Site s;
                    if (existing.isPresent()) {
                        s = existing.get();
                    } else {
                        s = new Site();
                        s.setId(ps.getId());
                        s.setUser(user);
                    }
                    // Resolve customer
                    Customer customer = customerRepository.findByIdAndUserId(ps.getCustomerId(), user.getId())
                            .orElseThrow(() -> new RuntimeException("customer not found: " + ps.getCustomerId()));
                    s.setCustomer(customer);
                    s.setName(ps.getName());
                    s.setAddress(ps.getAddress());
                    if (ps.getDeletedAt() != null) s.setDeletedAt(ps.getDeletedAt());
                    siteRepository.save(s);
                    sitesUpserted++;
                } catch (Exception e) {
                    errors.add("site:" + ps.getId() + " – " + e.getMessage());
                }
            }
        }

        // ── Notes ────────────────────────────────────────────────────────
        if (req.getNotes() != null) {
            for (PushNote pn : req.getNotes()) {
                try {
                    Optional<FieldNote> existing = fieldNoteRepository.findByIdAndUserId(pn.getId(), user.getId());
                    FieldNote fn;
                    if (existing.isPresent()) {
                        fn = existing.get();
                    } else {
                        fn = new FieldNote();
                        fn.setId(pn.getId());
                        fn.setUser(user);
                    }
                    Site site = siteRepository.findByIdAndUserId(pn.getSiteId(), user.getId())
                            .orElseThrow(() -> new RuntimeException("site not found: " + pn.getSiteId()));
                    fn.setSite(site);
                    fn.setTitle(pn.getTitle());
                    fn.setDescription(pn.getDescription());
                    fn.setLatitude(pn.getLatitude());
                    fn.setLongitude(pn.getLongitude());
                    fn.setNoteDate(pn.getNoteDate());
                    fn.setStatus(pn.getStatus());
                    if (pn.getDeletedAt() != null) fn.setDeletedAt(pn.getDeletedAt());
                    fieldNoteRepository.save(fn);
                    notesUpserted++;
                } catch (Exception e) {
                    errors.add("note:" + pn.getId() + " – " + e.getMessage());
                }
            }
        }

        return SyncPushResponse.builder()
                .customersUpserted(customersUpserted)
                .sitesUpserted(sitesUpserted)
                .notesUpserted(notesUpserted)
                .errors(errors)
                .pushedAt(Instant.now())
                .build();
    }

    /* ── Response DTOs ─────────────────────────────────────────────────── */

    @Data
    @Builder
    public static class SyncPullResponse {
        private List<CustomerResponse> customers;
        private List<SiteResponse> sites;
        private List<FieldNoteResponse> notes;
        private Instant pulledAt;
    }

    @Data
    @Builder
    public static class SyncPushResponse {
        private int customersUpserted;
        private int sitesUpserted;
        private int notesUpserted;
        private List<String> errors;
        private Instant pushedAt;
    }
}
