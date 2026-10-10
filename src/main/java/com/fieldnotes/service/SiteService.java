package com.fieldnotes.service;

import com.fieldnotes.dto.request.SiteRequest;
import com.fieldnotes.dto.response.SiteResponse;
import com.fieldnotes.entity.Customer;
import com.fieldnotes.entity.Site;
import com.fieldnotes.entity.User;
import com.fieldnotes.repository.CustomerRepository;
import com.fieldnotes.repository.SiteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SiteService {

    private final SiteRepository siteRepository;
    private final CustomerRepository customerRepository;

    public List<SiteResponse> getAll(User user) {
        return siteRepository.findActiveByUserId(user.getId())
                .stream().map(this::toResponse).toList();
    }

    public List<SiteResponse> getByCustomer(UUID customerId, User user) {
        return siteRepository.findActiveByCustomerIdAndUserId(customerId, user.getId())
                .stream().map(this::toResponse).toList();
    }

    public SiteResponse getOne(UUID id, User user) {
        Site site = siteRepository.findActiveByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Site not found"));
        return toResponse(site);
    }

    @Transactional
    public SiteResponse create(SiteRequest req, User user) {
        Customer customer = customerRepository
                .findByIdAndUserIdAndDeletedAtIsNull(req.getCustomerId(), user.getId())
                .orElseThrow(() -> new RuntimeException("Customer not found"));

        Site site = Site.builder()
                .user(user)
                .customer(customer)
                .name(req.getName())
                .address(req.getAddress())
                .build();
        return toResponse(siteRepository.save(site));
    }

    @Transactional
    public SiteResponse update(UUID id, SiteRequest req, User user) {
        Site site = siteRepository.findActiveByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Site not found"));

        if (!site.getCustomer().getId().equals(req.getCustomerId())) {
            Customer customer = customerRepository
                    .findByIdAndUserIdAndDeletedAtIsNull(req.getCustomerId(), user.getId())
                    .orElseThrow(() -> new RuntimeException("Customer not found"));
            site.setCustomer(customer);
        }

        site.setName(req.getName());
        site.setAddress(req.getAddress());
        return toResponse(siteRepository.save(site));
    }

    @Transactional
    public void delete(UUID id, User user) {
        Site site = siteRepository.findActiveByIdAndUserId(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Site not found"));
        site.setDeletedAt(Instant.now());
        siteRepository.save(site);
    }

    public SiteResponse toResponse(Site s) {
        return SiteResponse.builder()
                .id(s.getId())
                .name(s.getName())
                .address(s.getAddress())
                .customerId(s.getCustomer().getId())
                .customerName(s.getCustomer().getName())
                .createdAt(s.getCreatedAt())
                .updatedAt(s.getUpdatedAt())
                .deletedAt(s.getDeletedAt())
                .build();
    }
}
