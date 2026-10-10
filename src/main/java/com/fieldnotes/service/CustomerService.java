package com.fieldnotes.service;

import com.fieldnotes.dto.request.CustomerRequest;
import com.fieldnotes.dto.response.CustomerResponse;
import com.fieldnotes.entity.Customer;
import com.fieldnotes.entity.User;
import com.fieldnotes.repository.CustomerRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CustomerService {

    private final CustomerRepository customerRepository;

    public List<CustomerResponse> getAll(User user) {
        return customerRepository
                .findByUserIdAndDeletedAtIsNullOrderByNameAsc(user.getId())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    public CustomerResponse getOne(UUID id, User user) {
        Customer customer = customerRepository
                .findByIdAndUserIdAndDeletedAtIsNull(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        return toResponse(customer);
    }

    @Transactional
    public CustomerResponse create(CustomerRequest req, User user) {
        Customer customer = Customer.builder()
                .user(user)
                .name(req.getName())
                .phone(req.getPhone())
                .email(req.getEmail())
                .address(req.getAddress())
                .build();
        return toResponse(customerRepository.save(customer));
    }

    @Transactional
    public CustomerResponse update(UUID id, CustomerRequest req, User user) {
        Customer customer = customerRepository
                .findByIdAndUserIdAndDeletedAtIsNull(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        customer.setName(req.getName());
        customer.setPhone(req.getPhone());
        customer.setEmail(req.getEmail());
        customer.setAddress(req.getAddress());
        return toResponse(customerRepository.save(customer));
    }

    @Transactional
    public void delete(UUID id, User user) {
        Customer customer = customerRepository
                .findByIdAndUserIdAndDeletedAtIsNull(id, user.getId())
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        customer.setDeletedAt(Instant.now());
        customerRepository.save(customer);
    }

    public CustomerResponse toResponse(Customer c) {
        return CustomerResponse.builder()
                .id(c.getId())
                .name(c.getName())
                .phone(c.getPhone())
                .email(c.getEmail())
                .address(c.getAddress())
                .createdAt(c.getCreatedAt())
                .updatedAt(c.getUpdatedAt())
                .deletedAt(c.getDeletedAt())
                .build();
    }
}
