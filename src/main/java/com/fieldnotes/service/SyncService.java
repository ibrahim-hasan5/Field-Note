package com.fieldnotes.service;

import com.fieldnotes.dto.response.CustomerResponse;
import com.fieldnotes.dto.response.FieldNoteResponse;
import com.fieldnotes.dto.response.SiteResponse;
import com.fieldnotes.entity.User;
import com.fieldnotes.repository.CustomerRepository;
import com.fieldnotes.repository.FieldNoteRepository;
import com.fieldnotes.repository.SiteRepository;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.List;

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

    @Data
    @Builder
    public static class SyncPullResponse {
        private List<CustomerResponse> customers;
        private List<SiteResponse> sites;
        private List<FieldNoteResponse> notes;
        private Instant pulledAt;
    }
}
