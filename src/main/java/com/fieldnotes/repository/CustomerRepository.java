package com.fieldnotes.repository;

import com.fieldnotes.entity.Customer;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, UUID> {

    // Active customers for a user
    List<Customer> findByUserIdAndDeletedAtIsNullOrderByNameAsc(UUID userId);

    // Single active customer scoped to user
    Optional<Customer> findByIdAndUserIdAndDeletedAtIsNull(UUID id, UUID userId);

    // For sync pull: all records (including soft-deleted) updated after a timestamp
    @Query("SELECT c FROM Customer c WHERE c.user.id = :userId AND c.updatedAt > :since")
    List<Customer> findByUserIdAndUpdatedAtAfter(@Param("userId") UUID userId,
                                                  @Param("since") Instant since);

    // For initial full pull (no since filter)
    @Query("SELECT c FROM Customer c WHERE c.user.id = :userId")
    List<Customer> findAllByUserId(@Param("userId") UUID userId);
}
